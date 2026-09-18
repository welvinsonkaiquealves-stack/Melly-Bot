package cn.com.omnimind.baselib.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface AgentRunSummaryDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(summary: AgentRunSummary)

    @Query("SELECT * FROM agent_run_summaries WHERE agentRunId = :agentRunId LIMIT 1")
    suspend fun getByAgentRunId(agentRunId: String): AgentRunSummary?

    @Query("SELECT * FROM agent_run_summaries ORDER BY completedAt DESC LIMIT :limit")
    suspend fun getRecent(limit: Int): List<AgentRunSummary>

    @Query("SELECT * FROM agent_run_summaries WHERE conversationId = :conversationId ORDER BY completedAt DESC")
    suspend fun getByConversationId(conversationId: Long): List<AgentRunSummary>
}
