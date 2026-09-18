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
            budget.afterModelTurn(1_000)
            now += 1_000_000_000L
            budget.beforeContinuation()
        }
    }

    @Test
    fun thirteenthModelRoundFailsThroughExceptionPath() {
        val budget = AgentExecutionBudget(startedAtNanos = 0L, nanoTime = { 0L })

        repeat(AgentExecutionLimits.MAX_MODEL_ROUNDS) {
            budget.beforeModelRound()
            budget.afterModelTurn(0)
        }

        val error = runCatching { budget.beforeModelRound() }.exceptionOrNull()
        assertTrue(error is IllegalStateException)
        assertTrue(error?.message.orEmpty().contains("maximum model rounds"))
    }

    @Test
    fun executionDurationLimitFailsThroughExceptionPath() {
        var now = 0L
        val budget = AgentExecutionBudget(startedAtNanos = now, nanoTime = { now })
        budget.beforeModelRound()

        now = (AgentExecutionLimits.MAX_EXECUTION_DURATION_MS + 1L) * 1_000_000L
        val error = runCatching { budget.beforeContinuation() }.exceptionOrNull()

        assertTrue(error is IllegalStateException)
        assertTrue(error?.message.orEmpty().contains("maximum execution duration"))
    }

    @Test
    fun cumulativeCompletionLimitFailsThroughExceptionPath() {
        val budget = AgentExecutionBudget(startedAtNanos = 0L, nanoTime = { 0L })
        budget.beforeModelRound()
        budget.afterModelTurn(AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS.toInt())

        val error = runCatching { budget.afterModelTurn(1) }.exceptionOrNull()
        assertTrue(error is IllegalStateException)
        assertTrue(error?.message.orEmpty().contains("cumulative completion tokens"))
    }
}
