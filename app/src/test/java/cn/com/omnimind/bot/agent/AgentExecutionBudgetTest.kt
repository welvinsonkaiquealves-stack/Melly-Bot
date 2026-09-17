package cn.com.omnimind.bot.agent

import java.util.concurrent.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class AgentExecutionBudgetTest {
    @Test
    fun `normal execution stays below all limits`() = runBlocking {
        var now = 1_000L
        val budget = AgentExecutionBudget { now }

        budget.beforeModelRound(AgentExecutionLimits.MAX_MODEL_ROUNDS - 1)
        budget.recordCompletionTokens(
            AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS.toInt()
        )
        now += 1_000L

        assertEquals("ok", budget.runWithinRemainingTime { "ok" })
    }

    @Test
    fun `round limit fails before thirteenth model round`() {
        val budget = AgentExecutionBudget { 0L }

        val error = expectLimitError {
            budget.beforeModelRound(AgentExecutionLimits.MAX_MODEL_ROUNDS)
        }

        assertTrue(error.message.orEmpty().contains("model rounds"))
    }

    @Test
    fun `duration limit fails through execution limit exception`() {
        var now = 0L
        val budget = AgentExecutionBudget { now }
        now = AgentExecutionLimits.MAX_EXECUTION_DURATION_MS

        val error = expectLimitError { budget.ensureTimeRemaining() }

        assertTrue(error.message.orEmpty().contains("ms"))
    }

    @Test
    fun `cumulative completion token limit fails after 64k budget`() {
        val budget = AgentExecutionBudget { 0L }
        budget.recordCompletionTokens(
            AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS.toInt()
        )

        val error = expectLimitError { budget.recordCompletionTokens(1) }

        assertTrue(error.message.orEmpty().contains("completion tokens"))
    }

    @Test
    fun `parent cancellation remains cancellation instead of limit error`() = runBlocking {
        val budget = AgentExecutionBudget { 0L }
        val cancelledContext = Job().apply { cancel() }

        try {
            withContext(cancelledContext) {
                budget.runWithinRemainingTime { "unreachable" }
            }
            fail("Expected parent cancellation")
        } catch (error: CancellationException) {
            assertTrue(error !is AgentExecutionLimitExceededException)
        }
    }

    private fun expectLimitError(block: () -> Unit): AgentExecutionLimitExceededException {
        return try {
            block()
            fail("Expected AgentExecutionLimitExceededException")
            throw AssertionError("unreachable")
        } catch (error: AgentExecutionLimitExceededException) {
            error
        }
    }
}
