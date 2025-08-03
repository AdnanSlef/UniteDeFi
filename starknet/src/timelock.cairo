
#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Src {
    pub finality: u64,
    pub withdrawal: u64,
    pub cancellation: u64,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Dst {
    pub finality: u64,
    pub withdrawal: u64,
    pub public_withdrawal: u64,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Timelocks {
    pub deployed_at: u64,
    pub src: Src,
    pub dst: Dst,
}

// --- constructors / helpers as FREE FUNCTIONS ---
pub fn new(deployed_at: u64, src: Src, dst: Dst) -> Timelocks {
    Timelocks { deployed_at, src, dst }
}

pub fn rescue_start(t: @Timelocks, rescue_delay: u64) -> u64 {
    (*t).deployed_at + rescue_delay
}

// source chain
pub fn src_withdrawal_start(t: @Timelocks) -> u64 {
    (*t).deployed_at + (*t).src.finality
}
pub fn src_cancellation_start(t: @Timelocks) -> u64 {
    (*t).deployed_at + (*t).src.withdrawal
}
pub fn src_pub_cancellation_start(t: @Timelocks) -> u64 {
    (*t).deployed_at + (*t).src.cancellation
}

// destination chain
pub fn dst_withdrawal_start(t: @Timelocks) -> u64 {
    (*t).deployed_at + (*t).dst.finality
}
pub fn dst_pub_withdrawal_start(t: @Timelocks) -> u64 {
    (*t).deployed_at + (*t).dst.withdrawal
}
pub fn dst_cancellation_start(t: @Timelocks) -> u64 {
    (*t).deployed_at + (*t).dst.public_withdrawal
}