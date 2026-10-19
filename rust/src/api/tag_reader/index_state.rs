/// 曲库索引构建/更新所处的阶段。
pub enum IndexPhase {
    /// 尚未开始枚举文件。
    Preparing,
    /// 正在读取标签与扫描文件夹。
    Scanning,
    /// 正在把索引写回磁盘。
    Saving,
    /// 全部结束。
    Complete,
}

pub struct IndexActionState {
    /// completed / total
    pub progress: f64,

    /// describe action state
    pub message: String,

    /// 当前所处阶段
    pub phase: IndexPhase,

    /// 本次扫描累计无法读取而被跳过的文件数
    pub unreadable_total: u64,
}
