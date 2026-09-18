package cn.com.omnimind.bot.agent

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class AgentExecutionBudgetTest {
    @Test
    fun normalExecutionStaysWithinAllLimits() {
        var now = 0L
        val budget = AgentExecutionBudget(startedAtNanos = now, nanoTime = { now })

        repeat(3) { index ->
            assertEquals(index + 1, budget.beforeModelRound())
            budget.afterModelTurn(
                promptTokens = 2_000,
                completionTokens = 1_000,
                cachedTokens = 500,
                cacheCreationTokens = 100,
                toolCallCount = index
            )
            now += 1_000_000_000L
            budget.beforeContinuation()
        }

        assertEquals(
            AgentExecutionSnapshot(
                durationMs = 3_000L,
                modelRounds = 3,
                toolCallCount = 3,
                promptTokens = 6_000L,
                completionTokens = 3_000L,
                cachedTokens = 1_500L,
                cacheCreationTokens = 300L,
                reachedLimit = null
            ),
            budget.snapshot()
        )
    }

    @Test
    fun thirteenthModelRoundFailsThroughExceptionPath() {
        val budget = AgentExecutionBudget(startedAtNanos = 0L, nanoTime = { 0L })

        repeat(AgentExecutionLimits.MAX_MODEL_ROUNDS) {
            budget.beforeModelRound()
            budget.afterModelTurn(null, 0, null, null, 0)
        }

        val error = runCatching { budget.beforeModelRound() }.exceptionOrNull()
        assertTrue(error is AgentExecutionLimitException)
        assertTrue(error?.message.orEmpty().contains("maximum model rounds"))
        assertEquals(AgentExecutionLimit.MODEL_ROUNDS, budget.snapshot().reachedLimit)
    }

    @Test
    fun executionDurationLimitFailsThroughExceptionPath() {
        var now = 0L
        val budget = AgentExecutionBudget(startedAtNanos = now, nanoTime = { now })
        budget.beforeModelRound()

        now = (AgentExecutionLimits.MAX_EXECUTION_DURATION_MS + 1L) * 1_000_000L
        val error = runCatching { budget.beforeContinuation() }.exceptionOrNull()

        assertTrue(error is AgentExecutionLimitException)
        assertTrue(error?.message.orEmpty().contains("maximum execution duration"))
        assertEquals(AgentExecutionLimit.EXECUTION_DURATION, budget.snapshot().reachedLimit)
    }

    @Test
    fun completedTurnUsageIsRetainedWhenDurationLimitStopsContinuation() {
        var now = 0L
        val budget = AgentExecutionBudget(startedAtNanos = now, nanoTime = { now })
        budget.beforeModelRound()
        now = (AgentExecutionLimits.MAX_EXECUTION_DURATION_MS + 1L) * 1_000_000L

        runCatching { budget.afterModelTurn(100, 20, 30, 4, 2) }

        val snapshot = budget.snapshot()
        assertEquals(100L, snapshot.promptTokens)
        assertEquals(20L, snapshot.completionTokens)
        assertEquals(30L, snapshot.cachedTokens)
        assertEquals(4L, snapshot.cacheCreationTokens)
        assertEquals(2, snapshot.toolCallCount)
        assertEquals(AgentExecutionLimit.EXECUTION_DURATION, snapshot.reachedLimit)
    }

    @Test
    fun cumulativeCompletionLimitFailsThroughExceptionPath() {
        val budget = AgentExecutionBudget(startedAtNanos = 0L, nanoTime = { 0L })
        budget.beforeModelRound()
        budget.afterModelTurn(
            promptTokens = 50,
            completionTokens = AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS.toInt(),
            cachedTokens = 20,
            cacheCreationTokens = 10,
            toolCallCount = 1
        )

        val error = runCatching {
            budget.afterModelTurn(60, 1, 30, 11, 2)
        }.exceptionOrNull()
        assertTrue(error is AgentExecutionLimitException)
        assertTrue(error?.message.orEmpty().contains("cumulative completion tokens"))
        assertEquals(AgentExecutionLimit.COMPLETION_TOKENS, budget.snapshot().reachedLimit)
        assertEquals(64_001L, budget.snapshot().completionTokens)
        assertEquals(110L, budget.snapshot().promptTokens)
        assertEquals(3, budget.snapshot().toolCallCount)
    }

    @Test
    fun terminationReasonCoversNormalCancellationLimitsAndErrors() {
        val base = AgentExecutionSnapshot(1, 1, 0, 2, 3, 1, 0, null)
        val success = AgentResult.Success(AgentFinalResponse())
        val cancelled = AgentResult.Error(
            "cancelled",
            kotlinx.coroutines.CancellationException("user")
        )
        val failed = AgentResult.Error("failed", IllegalStateException("provider"))

        assertEquals(AgentRunTerminationReason.NORMAL, base.terminationReasonFor(success))
        assertEquals(AgentRunTerminationReason.USER_CANCELLED, base.terminationReasonFor(cancelled))
        assertEquals(AgentRunTerminationReason.USER_CANCELLED, base.terminationReasonFor(null, cancellation = true))
        assertEquals(AgentRunTerminationReason.ERROR, base.terminationReasonFor(failed))
        assertEquals(
            AgentRunTerminationReason.MODEL_ROUND_LIMIT,
            base.copy(reachedLimit = AgentExecutionLimit.MODEL_ROUNDS).terminationReasonFor(failed)
        )
        assertEquals(
            AgentRunTerminationReason.EXECUTION_DURATION_LIMIT,
            base.copy(reachedLimit = AgentExecutionLimit.EXECUTION_DURATION).terminationReasonFor(failed)
        )
        assertEquals(
            AgentRunTerminationReason.COMPLETION_TOKEN_LIMIT,
            base.copy(reachedLimit = AgentExecutionLimit.COMPLETION_TOKENS).terminationReasonFor(failed)
        )
    }
}
