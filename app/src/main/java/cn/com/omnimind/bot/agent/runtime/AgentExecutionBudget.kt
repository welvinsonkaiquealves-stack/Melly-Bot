package cn.com.omnimind.bot.agent

internal object AgentExecutionLimits {
    const val MAX_MODEL_ROUNDS: Int = 12
    const val MAX_EXECUTION_DURATION_MS: Long = 10 * 60 * 1000L
    const val MAX_CUMULATIVE_COMPLETION_TOKENS: Long = 64_000L
}

internal enum class AgentExecutionLimit {
    MODEL_ROUNDS,
    EXECUTION_DURATION,
    COMPLETION_TOKENS
}

internal enum class AgentRunTerminationReason {
    NORMAL,
    USER_CANCELLED,
    MODEL_ROUND_LIMIT,
    EXECUTION_DURATION_LIMIT,
    COMPLETION_TOKEN_LIMIT,
    ERROR
}

internal class AgentExecutionLimitException(
    val limit: AgentExecutionLimit,
    message: String
) : IllegalStateException(message)

internal data class AgentExecutionSnapshot(
    val durationMs: Long,
    val modelRounds: Int,
    val toolCallCount: Int,
    val promptTokens: Long,
    val completionTokens: Long,
    val cachedTokens: Long,
    val cacheCreationTokens: Long,
    val reachedLimit: AgentExecutionLimit?
)

class AgentExecutionBudget(
    private val startedAtNanos: Long = System.nanoTime(),
    private val nanoTime: () -> Long = System::nanoTime,
) {
    private var completedModelRounds: Int = 0
    private var cumulativeToolCalls: Int = 0
    private var cumulativePromptTokens: Long = 0L
    private var cumulativeCompletionTokens: Long = 0L
    private var cumulativeCachedTokens: Long = 0L
    private var cumulativeCacheCreationTokens: Long = 0L
    private var reachedLimit: AgentExecutionLimit? = null

    internal fun beforeModelRound(): Int {
        ensureWithinTimeLimit()
        if (completedModelRounds >= AgentExecutionLimits.MAX_MODEL_ROUNDS) {
            fail(
                AgentExecutionLimit.MODEL_ROUNDS,
                "Agent execution limit reached: maximum model rounds (${AgentExecutionLimits.MAX_MODEL_ROUNDS})."
            )
        }
        completedModelRounds += 1
        return completedModelRounds
    }

    internal fun afterModelTurn(
        promptTokens: Int?,
        completionTokens: Int?,
        cachedTokens: Int?,
        cacheCreationTokens: Int?,
        toolCallCount: Int
    ) {
        // The provider already consumed this turn. Account its usage before a
        // boundary check can stop continuation so the E2 summary remains exact.
        cumulativePromptTokens += normalizedTokens(promptTokens)
        cumulativeCompletionTokens += normalizedTokens(completionTokens)
        cumulativeCachedTokens += normalizedTokens(cachedTokens)
        cumulativeCacheCreationTokens += normalizedTokens(cacheCreationTokens)
        cumulativeToolCalls = (cumulativeToolCalls.toLong() + toolCallCount.coerceAtLeast(0))
            .coerceAtMost(Int.MAX_VALUE.toLong())
            .toInt()
        ensureWithinTimeLimit()
        if (cumulativeCompletionTokens > AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS) {
            fail(
                AgentExecutionLimit.COMPLETION_TOKENS,
                "Agent execution limit reached: cumulative completion tokens exceeded ${AgentExecutionLimits.MAX_CUMULATIVE_COMPLETION_TOKENS}."
            )
        }
    }

    internal fun beforeContinuation() {
        ensureWithinTimeLimit()
    }

    internal fun snapshot(): AgentExecutionSnapshot = AgentExecutionSnapshot(
        durationMs = elapsedMillis(),
        modelRounds = completedModelRounds,
        toolCallCount = cumulativeToolCalls,
        promptTokens = cumulativePromptTokens,
        completionTokens = cumulativeCompletionTokens,
        cachedTokens = cumulativeCachedTokens,
        cacheCreationTokens = cumulativeCacheCreationTokens,
        reachedLimit = reachedLimit
    )

    private fun ensureWithinTimeLimit() {
        if (elapsedMillis() > AgentExecutionLimits.MAX_EXECUTION_DURATION_MS) {
            fail(
                AgentExecutionLimit.EXECUTION_DURATION,
                "Agent execution limit reached: maximum execution duration exceeded ${AgentExecutionLimits.MAX_EXECUTION_DURATION_MS} ms."
            )
        }
    }

    private fun elapsedMillis(): Long =
        ((nanoTime() - startedAtNanos).coerceAtLeast(0L) / 1_000_000L)

    private fun normalizedTokens(value: Int?): Long =
        value?.coerceAtLeast(0)?.toLong() ?: 0L

    private fun fail(limit: AgentExecutionLimit, message: String): Nothing {
        if (reachedLimit == null) reachedLimit = limit
        throw AgentExecutionLimitException(limit, message)
    }
}

internal fun AgentExecutionSnapshot.terminationReasonFor(
    result: AgentResult?,
    cancellation: Boolean = false
): AgentRunTerminationReason = when (reachedLimit) {
    AgentExecutionLimit.MODEL_ROUNDS -> AgentRunTerminationReason.MODEL_ROUND_LIMIT
    AgentExecutionLimit.EXECUTION_DURATION -> AgentRunTerminationReason.EXECUTION_DURATION_LIMIT
    AgentExecutionLimit.COMPLETION_TOKENS -> AgentRunTerminationReason.COMPLETION_TOKEN_LIMIT
    null -> when {
        cancellation -> AgentRunTerminationReason.USER_CANCELLED
        result is AgentResult.Success -> AgentRunTerminationReason.NORMAL
        result is AgentResult.Error && result.exception is kotlinx.coroutines.CancellationException ->
            AgentRunTerminationReason.USER_CANCELLED
        else -> AgentRunTerminationReason.ERROR
    }
}
