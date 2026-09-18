package cn.com.omnimind.baselib.database

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "agent_run_summaries",
    indices = [
        Index(value = ["conversationId"]),
        Index(value = ["completedAt"])
    ]
)
data class AgentRunSummary(
    @PrimaryKey
    val agentRunId: String,
    val conversationId: Long?,
    val startedAt: Long,
    val completedAt: Long,
    val durationMs: Long,
    val modelRounds: Int,
    val toolCallCount: Int,
    val promptTokens: Long,
    val completionTokens: Long,
    val cachedTokens: Long,
    val cacheCreationTokens: Long,
    val terminationReason: String
)
