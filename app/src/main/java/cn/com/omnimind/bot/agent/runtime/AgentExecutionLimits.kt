package cn.com.omnimind.bot.agent

import kotlinx.coroutines.withTimeoutOrNull

/**
 * E1 safety fuses for one logical Agent execution.
 *
 * These are intentionally host constants, not user settings. Keep them named
 * and centralized so future tuning does not require hunting for literals in
 * the prompt loop.
 */
internal object AgentExecutionLimits {
    const val MAX_MODEL_ROUNDS: Int = 12
    const val MAX_EXECUTION_DURATION_MS: Long = 10L * 60L * 1000L
    const val MAX_CUMULATIVE_COMPLETION_TOKENS: Long = 64L * 1024L
}

/**
 * Deliberately extends Exception rather than CancellationException.
 *
 * Limit exhaustion is an ACP execution error and must flow through the
 * existing AgentResult.Error path. User/parent cancellation remains a distinct
 * CancellationException path and must continue to map to ACP CANCELLED.
 */
internal class AgentExecutionLimitExceededException(message: String) : Exception(message)

internal class AgentExecutionBudget(
    private val nowMillis: () -> Long = { System.nanoTime() / 1_000_000L },
) {
    private val startedAtMillis = nowMillis()
    private var cumulativeCompletionTokens: Long = 0L

    fun beforeModelRound(completedModelRounds: Int) {
        ensureTimeRemaining()
        if (completedModelRounds >= AgentExecutionLimits.MAX_MODEL_ROUNDS) {
            throw AgentExecutionLimitExceededException(
                "Agent execution exceeded ${AgentExecutionLimits.MAX_MODEL_ROUNDS} model rounds."
            )
        }
    }

    fun recordCompletionTokens(completionTokens: Int?) {
        if (completionTokens != null && completionTokens > 0) {
            cumulativeCompletionTokens =
                (cumulativeCompletionTokens + completionTokens.toLong())
                    .coerceAtMost(Long.MAX_VALUE)
        }
        if (cumulativeCompletionTokens > AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS) {
            throw AgentExecutionLimitExceededException(
                "Agent execution exceeded ${AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS} cumulative completion tokens."
            )
        }
        ensureTimeRemaining()
    }

    fun ensureTimeRemaining() {
        if (elapsedMillis() >= AgentExecutionLimits.MAX_EXECUTION_DURATION_MS) {
            throw durationExceeded()
        }
    }

    suspend fun <T : Any> runWithinRemainingTime(block: suspend () -> T): T {
        val remaining = remainingMillis()
        return withTimeoutOrNull(remaining) { block() } ?: throw durationExceeded()
    }

    private fun remainingMillis(): Long {
        val remaining = AgentExecutionLimits.MAX_EXECUTION_DURATION_MS - elapsedMillis()
        if (remaining <= 0L) throw durationExceeded()
        return remaining
    }

    private fun elapsedMillis(): Long = (nowMillis() - startedAtMillis).coerceAtLeast(0L)

    private fun durationExceeded(): AgentExecutionLimitExceededException =
        AgentExecutionLimitExceededException(
            "Agent execution exceeded ${AgentExecutionLimits.MAX_EXECUTION_DURATION_MS} ms."
        )
}
