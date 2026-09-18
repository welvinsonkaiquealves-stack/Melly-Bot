package cn.com.omnimind.bot.agent

internal object AgentExecutionLimits {
    const val MAX_MODEL_ROUNDS: Int = 12
    const val MAX_EXECUTION_DURATION_MS: Long = 10 * 60 * 1000L
    const val MAX_CUMULATIVE_COMPLETION_TOKENS: Long = 64_000L
}

internal class AgentExecutionBudget(
    private val startedAtNanos: Long = System.nanoTime(),
    private val nanoTime: () -> Long = System::nanoTime,
) {
    private var completedModelRounds: Int = 0
    private var cumulativeCompletionTokens: Long = 0L

    fun beforeModelRound(): Int {
        ensureWithinTimeLimit()
        check(completedModelRounds < AgentExecutionLimits.MAX_MODEL_ROUNDS) {
            "Agent execution limit reached: maximum model rounds (${AgentExecutionLimits.MAX_MODEL_ROUNDS})."
        }
        completedModelRounds += 1
        return completedModelRounds
    }

    fun afterModelTurn(completionTokens: Int?) {
        ensureWithinTimeLimit()
        val normalizedCompletionTokens = completionTokens?.coerceAtLeast(0)?.toLong() ?: 0L
        cumulativeCompletionTokens += normalizedCompletionTokens
        check(cumulativeCompletionTokens <= AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS) {
            "Agent execution limit reached: cumulative completion tokens exceeded ${AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS}."
        }
    }

    fun beforeContinuation() {
        ensureWithinTimeLimit()
    }

    private fun ensureWithinTimeLimit() {
        val elapsedNanos = (nanoTime() - startedAtNanos).coerceAtLeast(0L)
        val elapsedMillis = elapsedNanos / 1_000_000L
        check(elapsedMillis <= AgentExecutionLimits.MAX_EXECUTION_DURATION_MS) {
            "Agent execution limit reached: maximum execution duration exceeded ${AgentExecutionLimits.MAX_EXECUTION_DURATION_MS} ms."
        }
    }
}
