```verilog
`timescale 1ns/1ps

module axis_async_fifo_adapter #
(
    parameter DEPTH = 4096,
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH>8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH+7)/8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH>8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter RAM_PIPELINE = 1,
    parameter OUTPUT_FIFO_ENABLE = 0,
    parameter FRAME_FIFO = 0,
    parameter USER_BAD_FRAME_VALUE = 1'b1,
    parameter USER_BAD_FRAME_MASK = 1'b1,
    parameter DROP_OVERSIZE_FRAME = FRAME_FIFO,
    parameter DROP_BAD_FRAME = 0,
    parameter DROP_WHEN_FULL = 0,
    parameter MARK_WHEN_FULL = 0,
    parameter PAUSE_ENABLE = 0,
    parameter FRAME_PAUSE = FRAME_FIFO
)
(
    input  wire                     s_clk,
    input  wire                     s_rst,
    input  wire [S_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [S_KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [ID_WIDTH-1:0]      s_axis_tid,
    input  wire [DEST_WIDTH-1:0]    s_axis_tdest,
    input  wire [USER_WIDTH-1:0]    s_axis_tuser,
    input  wire                     m_clk,
    input  wire                     m_rst,
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser,
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    output wire [$clog2(DEPTH):0]   s_status_depth,
    output wire [$clog2(DEPTH):0]   s_status_depth_commit,
    output wire                     s_status_overflow,
    output wire                     s_status_bad_frame,
    output wire                     s_status_good_frame,
    output wire [$clog2(DEPTH):0]   m_status_depth,
    output wire [$clog2(DEPTH):0]   m_status_depth_commit,
    output wire                     m_status_overflow,
    output wire                     m_status_bad_frame,
    output wire                     m_status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam S_KEEP_WIDTH_LOG = S_KEEP_WIDTH;
    localparam M_KEEP_WIDTH_LOG = M_KEEP_WIDTH;

    // Internal signals for cross-clock domain
    wire s_axis_tvalid_sync;
    wire s_axis_tready_sync;
    wire s_axis_tlast_sync;
    wire s_axis_tid_sync [ID_WIDTH-1:0];
    wire s_axis_tdest_sync [DEST_WIDTH-1:0];
    wire s_axis_tuser_sync [USER_WIDTH-1:0];
    wire s_pause_req_sync;
    wire s_pause_ack_sync;
    wire s_axis_tvalid_synced; // Registered version for logic

    wire m_axis_tvalid_sync;
    wire m_axis_tready_sync;
    wire m_axis_tlast_sync;
    wire m_axis_tid_sync [ID_WIDTH-1:0];
    wire m_axis_tdest_sync [DEST_WIDTH-1:0];
    wire m_axis_tuser_sync [USER_WIDTH-1:0];
    wire m_pause_req_sync;
    wire m_pause_ack_sync;
    wire m_axis_tvalid_synced;

    // Cross Clock Domain: S -> M (Gray Encoding)
    // We need to capture the state of the S-side signals when the M-side logic needs them
    // However, since this is a FIFO, the data is stored in the FIFO.
    // The critical path is: S-side writes data -> FIFO -> M-side reads data.
    // The "width adapter" logic happens on the M-side read path (or S-side write path depending on implementation).
    // Given the requirement "Width conversion stays in one clock", we will perform the packing/unpacking
    // on the side where the data width changes relative to the FIFO depth.
    // Actually, the FIFO stores the data. If S_width != M_width, we must pack/unpack.
    // Strategy: Store packed data in the FIFO if S_width > M_width? Or unpack on read?
    // Standard approach: If S_width > M_width, we pack on S-side (write) and store packed.
    // If S_width < M_width, we unpack on M-side (read) and store unpacked.
    // If equal, no packing/unpacking needed.
    
    // Let's determine the storage width.
    // To minimize complexity and ensure "width conversion stays in one clock", 
    // we will pack on the source side if Source > Dest, and unpack on the destination side if Source < Dest.
    // If Source > Dest: Pack S_data -> FIFO (width M_DATA_WIDTH). Unpack on M-side? No, FIFO stores packed.
    // Wait, if S=16, M=8. We pack 2 bytes into 1 word? No, AXI Stream is byte-aligned usually but tdata is arbitrary.
    // If S=16, M=8. We need to store 16 bits. We can store as 2x8 or 1x16.
    // If we store as 1x16, the FIFO depth must accommodate the larger width.
    // If we store as 2x8, we need to manage pointers carefully.
    // Simpler approach for generic widths: 
    // 1. Calculate LCM of widths? Too complex for generic Verilog without synthesis support.
    // 2. Assume we store the data in the FIFO at the width of the side that is "larger" or a common multiple?
    // 3. Most robust generic implementation: Store data in the FIFO at the width of the *source* (S_DATA_WIDTH) 
    //    if S_DATA_WIDTH >= M_DATA_WIDTH, else store at M_DATA_WIDTH? 
    //    No, if S=16, M=8. We receive 16 bits. We need to send 8 bits. We must split the 16-bit packet into two 8-bit packets.
    //    This implies the FIFO must hold the intermediate state.
    //    If S=8, M=16. We receive 8 bits. We need to send 16 bits. We must combine two 8-bit packets.
    
    // Implementation Plan:
    // The FIFO will store data in a unified internal width. 
    // To keep it simple and correct for arbitrary widths:
    // We will use a FIFO that stores data at the width of the *larger* of the two, 
    // but we need to handle the splitting/merging logic.
    // Actually, the standard way for "width adapter" in a FIFO is:
    // If S > M: Pack multiple S words into one FIFO entry? No, that breaks packet boundaries if not careful.
    // Better: The FIFO stores the data at the width of the *source* (S). 
    // When reading, if S > M, we split the stored word into multiple M words.
    // When writing, if S < M, we merge multiple S words into one M word? No, that requires buffering multiple S words.
    
    // Let's refine:
    // Case 1: S_WIDTH >= M_WIDTH.
    //   Write: Take S_DATA_WIDTH bits. Store in FIFO (width S_DATA_WIDTH).
    //   Read: Take FIFO data (S_DATA_WIDTH). Split into M_DATA_WIDTH chunks. Send to M.
    //   Note: If S=16, M=8. One S packet (16 bits) becomes two M packets (8+8 bits).
    //   We need to track if we are in the middle of a split.
    //   Since tlast is per packet, if S=16, M=8, and tlast=1 on S, then the second 8-bit chunk is also tlast=1.
    
    // Case 2: S_WIDTH < M_WIDTH.
    //   Write: Take S_DATA_WIDTH bits. Store in FIFO (width S_DATA_WIDTH).
    //   Read: Take FIFO data (S_DATA_WIDTH). Merge with previous? 
    //   Wait, if S=8, M=16. We receive 8 bits. We store 8 bits. Next 8 bits come. We merge them into 16 bits.
    //   This requires buffering at least 2 S-words to form 1 M-word.
    //   So the FIFO must store data at the width of the *smaller* side? 
    //   If we store at smaller width (S), we can merge on read.
    //   If we store at larger width (M), we can split on read.
    //   Which is better? 
    //   If S=8, M=16. Store at 8. Read: merge 2->1.
    //   If S=16, M=8. Store at 16. Read: split 1->2.
    //   This seems consistent. The FIFO internal width = max(S_DATA_WIDTH, M_DATA_WIDTH).
    //   Wait, if S=8, M=16. Max is 16. If we store at 16, we can't store a single 8-bit word efficiently without padding?
    //   Actually, if we store at 16, we can store one 8-bit word in the lower half, upper half zero.
    //   Then next 8-bit word comes, we combine? No, that's complex state.
    //   
    //   Revised Plan:
    //   Internal FIFO Width = S_DATA_WIDTH. (Always store at source width).
    //   If S > M: 
    //     Write: Store S word.
    //     Read: Split S word into M words.
    //   If S < M:
    //     Write: Store S word.
    //     Read: We need to accumulate S words to form M words.
    //     This requires a "merge buffer" on the read path.
    //   
    //   Let's check the constraint: "Width conversion stays in one clock".
    //   If S < M, we need to hold the first S-word while waiting for the second. This is naturally handled by the FIFO depth and logic.
    //   If S > M, we split one read into multiple writes.
    
    // Let's define the internal FIFO width.
    // To support both directions simply:
    // We will store data at S_DATA_WIDTH.
    // If S_DATA_WIDTH > M_DATA_WIDTH: Splitting logic on Read path.
    // If S_DATA_WIDTH < M_DATA_WIDTH: Merging logic on Read path (accumulate S words into M word).
    // If S_DATA_WIDTH == M_DATA_WIDTH: Pass through.
    
    // Wait, if S < M, and we store at S. 
    // Example: S=8, M=16.
    // FIFO stores 8-bit words.
    // Read logic: 
    //   State 0: Have 0 bits. Wait for 1st S-word.
    //   State 1: Have 1st S-word. Wait for 2nd S-word.
    //   State 2: Have 2nd S-word. Merge -> 16-bit M-word. Output.
    // This works.
    
    // Example: S=16, M=8.
    // FIFO stores 16-bit words.
    // Read logic:
    //   Take 16-bit word.
    //   Output upper 8 bits as M-word 1.
    //   Output lower 8 bits as M-word 2.
    // This works.
    
    // So, Internal FIFO Width = S_DATA_WIDTH.
    // We need a FIFO that supports S_DATA_WIDTH.
    // But wait, if S < M, we might need to buffer more than one S-word to fill an M-word?
    // Yes, but the FIFO stores the stream. The "merge" logic is just a state machine on the read side.
    // The FIFO depth is defined in terms of "S-words".
    // If S=8, M=16. Depth=4096 means 4096 8-bit words.
    // If we need to output a 16-bit word, we consume 2 entries from the FIFO.
    // This is fine.
    
    // One edge case: tlast.
    // If S=16, M=8. S packet has tlast=1. It contains 16 bits.
    // We split into two 8-bit packets. Both should have tlast=1.
    // If S=8, M=16. S packet 1 (tlast=0), S packet 2 (tlast=1).
    // We merge them into one 16-bit packet with tlast=1.
    
    // Implementation Details:
    // 1. S-side: Capture valid, last, tid, dest, user, pause_req.
    // 2. M-side: Capture valid, ready, last, tid, dest, user, pause_req.
    // 3. FIFO: Stores {tdata, tlast, tid, dest, user} at S_DATA_WIDTH + overhead.
    //    Actually, we need to store the metadata too.
    //    Let's create a struct-like packing.
    //    Since Verilog-2001, we use packed arrays or separate wires.
    //    Let's use separate wires for clarity and compatibility.
    
    // FIFO Depth is in terms of S-words.
    // We need to handle the case where S < M and we need to merge.
    // The FIFO pointer arithmetic must be careful.
    
    // Let's define the internal data structure.
    // We will store: tdata (S_WIDTH), tlast (1), tid (ID_WIDTH), dest (DEST_WIDTH), user (USER_WIDTH).
    // Total width per entry = S_DATA_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH.
    
    // Cross Clock Domain Logic (Gray Encoder/Decoder)
    // We will use a simple asynchronous FIFO for the control signals (valid/ready/pause) 
    // to synchronize the pointers and status, but the data itself is in the main FIFO.
    // Actually, the standard way is:
    // S-side writes to FIFO. M-side reads from FIFO.
    // S-side tvalid is asserted when data is ready.
    // M-side tready is asserted when FIFO has data.
    // We need to synchronize tvalid and tready across clocks.
    // We can use a simple 2-stage synchronizer for the control signals.
    
    // S-side Control Sync
    wire s_valid_synced;
    wire s_ready_synced;
    wire s_last_synced;
    wire s_tid_synced [ID_WIDTH-1:0];
    wire s_dest_synced [DEST_WIDTH-1:0];
    wire s_user_synced [USER_WIDTH-1:0];
    wire s_pause_req_synced;
    
    // M-side Control Sync
    wire m_valid_synced;
    wire m_ready_synced;
    wire m_last_synced;
    wire m_tid_synced [ID_WIDTH-1:0];
    wire m_dest_synced [DEST_WIDTH-1:0];
    wire m_user_synced [USER_WIDTH-1:0];
    wire m_pause_req_synced;

    // S-side Synchronizer
    reg s_valid_synced_reg;
    reg s_last_synced_reg;
    reg s_tid_synced_reg [ID_WIDTH-1:0];
    reg s_dest_synced_reg [DEST_WIDTH-1:0];
    reg s_user_synced_reg [USER_WIDTH-1:0];
    reg s_pause_req_synced_reg;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_valid_synced_reg <= 1'b0;
            s_last_synced_reg <= 1'b0;
            s_tid_synced_reg <= '{default: 1'b0};
            s_dest_synced_reg <= '{default: 1'b0};
            s_user_synced_reg <= '{default: 1'b0};
            s_pause_req_synced_reg <= 1'b0;
        end else begin
            // Simple 2-stage sync for validity
            wire s_valid_sync1 = s_axis_tvalid;
            wire s_valid_sync2 = s_valid_sync1;
            s_valid_synced_reg <= s_valid_sync2;
            
            // For other signals, we sync when valid is high? 
            // Or just sync them directly? 
            // Best practice: Sync the data signals when valid is detected.
            // But for simplicity in this constrained environment, we will sync the signals 
            // using a 2-stage flip-flop chain triggered by s_clk, but only latch when s_axis_tvalid is high?
            // No, that's complex. 
            // Standard approach: 
            // 1. Sync s_axis_tvalid to s_clk domain.
            // 2. When s_axis_tvalid_sync is 1, capture the data.
            // 3. But the data might change.
            // Let's use a standard async FIFO pointer synchronization method for the control signals.
            // However, since we are building the FIFO, we can just sync the control signals 
            // using a simple 2-stage synchronizer and assume they are stable when valid.
            // To be safe, we will sync the data signals using a "valid-latch" approach.
            
            // Re-evaluating: The most robust way for this specific problem (AXI Stream Adapter)
            // is to have the S-side logic drive the FIFO write, and M-side logic drive the FIFO read.
            // The "s_axis_tready" is generated by the FIFO logic based on M-side readiness.
            // We need to pass M-side tready to S-side.
            // And S-side tvalid to M-side (via FIFO pointers).
            
            // Let's implement a standard Async FIFO for the pointers and status, 
            // and use the data FIFO for the payload.
            // But the prompt asks for a single module.
            
            // Let's simplify the sync:
            // We will use a 2-stage synchronizer for all control signals crossing the boundary.
            // For data signals (tdata, etc.), we will capture them in the S-clock domain when tvalid is high,
            // and store them in the FIFO.
            // For the M-side, we read from the FIFO and generate tvalid.
            
            // S-side Sync Logic
            wire s_valid_sync1 = s_axis_tvalid;
            wire s_valid_sync2 = s_valid_sync1;
            s_valid_synced <= s_valid_sync2;
            
            // Capture data when valid is high in S domain
            // We need to ensure we don't capture stale data.
            // We will use a latch or register that updates on s_clk when s_valid_synced is 1.
            // But s_valid_synced is already registered.
            // Let's use a separate register for data capture.
            
            // Actually, the standard pattern:
            // s_axis_tvalid -> sync -> s_valid_synced
            // When s_valid_synced is 1, we capture s_axis_tdata, etc.
            // But we need to do this on the s_clk edge.
            
            // Let's define the capture logic inside the always block.
            // We need to know if we are in a "valid" cycle.
            // We can use a 2-bit state machine or just a flag.
            
            // Simpler: Use a 2-stage synchronizer for the data signals too?
            // No, data is wide.
            // We will use a "valid" flag to gate the data capture.
            
            // Let's restart the sync logic design for clarity.
            // We need to pass: tvalid, tlast, tid, dest, user, pause_req from S to M (via FIFO pointers).
            // We need to pass: tready, pause_ack from M to S.
            
            // S -> M (Write side):
            // The FIFO write pointer is in S domain.
            // The FIFO read pointer is in M domain.
            // The FIFO depth is known.
            // We need to synchronize the pointers to generate ready/valid.
            
            // M -> S (Read side):
            // M-side tready is needed by S-side to assert tready.
            // We need to sync m_axis_tready to S domain.
            
            // S -> M (Data):
            // Data is stored in the FIFO. No sync needed for data itself, just pointers.
            
            // M -> S (Control):
            // m_axis_tready needs to be synced to S domain to drive s_axis_tready.
            // m_pause_req needs to be synced to S domain to drive s_pause_ack logic.
            
            // S -> M (Control):
            // s_pause_req needs to be synced to M domain to drive m_pause_ack logic.
            // s_axis_tvalid is implicitly handled by the FIFO write pointer.
            
            // So the main challenge is synchronizing m_axis_tready to S domain.
            // And synchronizing s_pause_req to M domain.
            
            // Let's implement the sync logic.
            
            // Sync m_axis_tready to S domain
            wire m_ready_sync1 = m_axis_tready;
            wire m_ready_sync2 = m_ready_sync1;
            wire m_ready_synced = m_ready_sync2;
            
            // Sync s_pause_req to M domain
            wire s_pause_req_sync1 = s_pause_req;
            wire s_pause_req_sync2 = s_pause_req_sync1;
            wire s_pause_req_synced_m = s_pause_req_sync2;
            
            // Sync m_pause_req to S domain
            wire m_pause_req_sync1 = m_pause_req;
            wire m_pause_req_sync2 = m_pause_req_sync1;
            wire m_pause_req_synced_s = m_pause_req_sync2;
            
            // Now, let's design the FIFO.
            // We need a FIFO that stores:
            // tdata [S_DATA_WIDTH-1:0]
            // tlast
            // tid [ID_WIDTH-1:0]
            // dest [DEST_WIDTH-1:0]
            // user [USER_WIDTH-1:0]
            
            // We will use a generic FIFO implementation inside this module.
            // Since we cannot use vendor primitives, we will implement a simple RAM-based FIFO.
            // To handle the width conversion, we will store the data as-is (S_WIDTH).
            // The width conversion logic will be applied during the read process.
            
            // FIFO Parameters
            localparam FIFO_DEPTH = DEPTH;
            localparam FIFO_ADDR_WIDTH = $clog2(FIFO_DEPTH);
            
            // FIFO Memory
            // We need to store the data.
            // Let's create a packed structure for the FIFO entry.
            // Since Verilog-2001, we can use packed arrays.
            // But to be safe and clear, we will use separate wires for the memory array.
            // However, declaring a large array of structs is verbose.
            // We will use a single packed array for the memory to save space and simplify indexing.
            
            // Memory Width Calculation
            localparam FIFO_DATA_WIDTH = S_DATA_WIDTH + 1 + ID_WIDTH + DEST_WIDTH + USER_WIDTH;
            
            reg [FIFO_DATA_WIDTH-1:0] fifo_mem [FIFO_DEPTH-1:0];
            reg [FIFO_ADDR_WIDTH-1:0] fifo_wptr, fifo_rptr;
            reg fifo_wfull, fifo_rfull, fifo_empty;
            reg [FIFO_ADDR_WIDTH-1:0] fifo_wptr_gray, fifo_rptr_gray;
            
            // Write Logic (S Domain)
            // Write enable is s_axis_tvalid AND not s_pause_req_synced_s (if PAUSE_ENABLE)
            // Also check for full.
            
            wire s_write_en = s_axis_tvalid && !s_pause_req_synced_s && !s_status_overflow;
            
            // Check Full
            wire fifo_full = (fifo_wptr == fifo_rptr) && fifo_wfull;
            wire fifo_almost_full = (fifo_wptr == fifo_rptr) && fifo_wfull; // Actually wfull indicates full
            
            // Write Pointer Logic
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    fifo_wptr <= 1'b0;
                    fifo_wfull <= 1'b0;
                    fifo_rptr <= 1'b0;
                    fifo_empty <= 1'b1;
                    fifo_rfull <= 1'b0;
                end else begin
                    fifo_wptr <= s_write_en ? fifo_wptr + 1'b1 : fifo_wptr;
                    fifo_wfull <= s_write_en && (fifo_wptr == fifo_rptr);
                    fifo_empty <= !s_write_en && (fifo_wptr == fifo_rptr);
                    fifo_rfull <= s_write_en && (fifo_wptr == fifo_rptr); // Simplified
                end
            end
            
            // Write Data Capture
            // We need to capture the data when s_write_en is high.
            // But we need to ensure we capture the correct data.
            // We will use a latch or register that updates on the clock edge when write_en is high.
            // However, to avoid metastability, we should capture the data in the same cycle as the pointer update.
            
            reg [S_DATA_WIDTH-1:0] s_tdata_reg;
            reg s_tlast_reg;
            reg [ID_WIDTH-1:0] s_tid_reg;
            reg [DEST_WIDTH-1:0] s_dest_reg;
            reg [USER_WIDTH-1:0] s_user_reg;
            
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    s_tdata_reg <= 1'b0;
                    s_tlast_reg <= 1'b0;
                    s_tid_reg <= '{default: 1'b0};
                    s_dest_reg <= '{default: 1'b0};
                    s_user_reg <= '{default: 1'b0};
                end else begin
                    if (s_write_en) begin
                        s_tdata_reg <= s_axis_tdata;
                        s_tlast_reg <= s_axis_tlast;
                        s_tid_reg <= s_axis_tid;
                        s_dest_reg <= s_axis_tdest;
                        s_user_reg <= s_axis_tuser;
                    end
                end
            end
            
            // Write to Memory
            always @(posedge s_clk or posedge s_rst) begin
                if (s_rst) begin
                    fifo_mem <= '{default: 1'b0};
                end else begin
                    if (s_write_en) begin
                        // Pack the data
                        // Order: tdata, tlast, tid, dest, user
                        // We need to handle the case where some widths are 0.
                        // If width is 0, the slice is empty.
                        
                        // Construct the packed value
                        // We will use a temporary variable to pack
                        // Since we are in Verilog-2001, we can use concatenation.
                        
                        // Note: If ID_ENABLE, DEST_ENABLE, USER_ENABLE are 0, the widths are 0.
                        // The parameters define the widths.
                        
                        // We need to be careful with the packing order.
                        // Let's assume: {tdata, tlast, tid, dest, user}
                        
                        // But wait, if ID_WIDTH is 0, the slice is empty.
                        // We can use the parameters to construct the width.
                        
                        // Let's create a helper logic for packing.
                        // Since we cannot use functions, we will do it inline.
                        
                        // We will use a large enough temporary register to hold the packed data.
                        // But we don't know the total width at compile time easily for the temp reg.
                        // We can use the FIFO_DATA_WIDTH calculated above.
                        
                        // Let's assume the packing order:
                        // [USER_WIDTH-1:0] user
                        // [DEST_WIDTH-1:0] dest
                        // [ID_WIDTH-1:0] tid
                        // [1:0] tlast
                        // [S_DATA_WIDTH-1:0] tdata
                        // Total = USER + DEST + ID + 1 + S_DATA_WIDTH + 1 (for tlast)
                        // Wait, tlast is 1 bit.
                        // Total = USER + DEST + ID + 1 + S_DATA_WIDTH + 1 = USER + DEST + ID + S_DATA_WIDTH + 2.
                        // My previous calculation was 1 + ID + DEST + USER + S_DATA_WIDTH.
                        // I missed the tlast bit in the sum? No, I included it.
                        // Let's re-calculate:
                        // S_DATA_WIDTH + 1 (tlast) + ID_WIDTH + DEST_WIDTH + USER_WIDTH.
                        // This matches FIFO_DATA_WIDTH.
                        
                        // Packing:
                        // We need to shift the fields into the correct positions.
                        // Let's assume the order in the memory is:
                        // {tdata, tlast, tid, dest, user}
                        // But we need to handle the widths correctly.
                        
                        // Since we are using a packed array, we can just concatenate.
                        // But we need to make sure the widths are correct.
                        
                        // Let's use a temporary variable to hold the packed data.
                        // We can't declare a reg with dynamic width easily in Verilog-2001 without localparams.
                        // We have FIFO_DATA_WIDTH.
                        
                        // Let's construct the packed value.
                        // We will assume the order: {tdata, tlast, tid, dest, user}
                        // But we need to handle the case where widths are 0.
                        // If width is 0, the slice is empty.
                        
                        // Example: S=8, ID=0, DEST=0, USER=1.
                        // Packed: {s_tdata, s_tlast, s_tid[0:0], s_dest[0:0], s_user[0:0]}
                        // If ID=0, s_tid[0:0] is empty.
                        
                        // We can use the parameters to construct the concatenation.
                        // But Verilog concatenation requires constant widths.
                        // The parameters are constant.
                        
                        // Let's define the packing explicitly.
                        // We will use a large enough temp reg and shift.
                        // Or just concatenate with the parameters.
                        
                        // Let's try to construct the packed value directly.
                        // We need to be careful about the order.
                        // Let's use the order: {tdata, tlast, tid, dest, user}
                        
                        // Since we cannot use dynamic concatenation, we will use the parameters.
                        // But the parameters are constants.
                        
                        // Let's assume the following packing:
                        // {s_tdata, s_tlast, s_tid, s_dest, s_user}
                        // This works if the widths are correct.
                        
                        // However, if ID_WIDTH is 0, s_tid is 0-width.
                        // Verilog allows 0-width slices in concatenation.
                        
                        // So we can do:
                        // fifo_mem[fifo_wptr] <= {s_tdata, s_tlast, s_tid, s_dest, s_user};
                        
                        // But wait, the order matters for the read side.
                        // We will read it back in the same order.
                        
                        fifo_mem[fifo_wptr] <= {s_tdata, s_tlast, s_tid, s_dest, s_user};
                    end
                end
            end
            
            // Read Logic (M Domain)
            // Read enable is m_axis_tready AND not m_pause_req_synced_s (if PAUSE_ENABLE)
            // Also check for empty.
            
            wire m_read_en = m_axis_tready && !m_pause_req_synced_s && !fifo_empty;
            
            // Read Pointer Logic
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    fifo_rptr <= 1'b0;
                    fifo_rfull <= 1'b0;
                    fifo_empty <= 1'b1;
                    fifo_wfull <= 1'b0;
                end else begin
                    fifo_rptr <= m_read_en ? fifo_rptr + 1'b1 : fifo_rptr;
                    fifo_rfull <= m_read_en && (fifo_rptr == fifo_wptr);
                    fifo_empty <= !m_read_en && (fifo_rptr == fifo_wptr);
                end
            end
            
            // Read Data
            reg [S_DATA_WIDTH-1:0] r_tdata;
            reg r_tlast;
            reg [ID_WIDTH-1:0] r_tid;
            reg [DEST_WIDTH-1:0] r_dest;
            reg [USER_WIDTH-1:0] r_user;
            
            always @(posedge m_clk or posedge m_rst) begin
                if (m_rst) begin
                    r_tdata <= 1'b0;
                    r_tlast <= 1'b0;
                    r_tid <= '{default: 1'b0};
                    r_dest <= '{default: 1'b0};
                    r_user <= '{default: 1'b0};
                end else begin
                    if (m_read_en) begin
                        // Unpack the data
                        // Order: {tdata, tlast, tid, dest, user}
                        // We need to extract the fields.
                        
                        // tdata: [S_DATA_WIDTH-1:0]
                        // tlast: [1:0] (Wait, tlast is 1 bit. It is at position S_DATA_WIDTH)
                        // tid: [ID_WIDTH-1:0]
                        // dest: [DEST_WIDTH-1:0]
                        // user: [USER_WIDTH-1:0]
                        
                        // Let's assume the packing was: {tdata, tlast, tid, dest, user}
                        // So:
                        // tdata = mem[S_DATA_WIDTH-1:0]
                        // tlast = mem[S_DATA_WIDTH]
                        // tid = mem[S_DATA_WIDTH+1 : S_DATA_WIDTH+ID_WIDTH]
                        // dest = mem[S_DATA_WIDTH+ID_WIDTH+1 : S_DATA_WIDTH+ID_WIDTH+DEST_WIDTH]
                        // user = mem[S_DATA_WIDTH+ID_WIDTH+DEST_WIDTH+1 : S_DATA_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH]
                        
                        // But we need to handle the case where widths are 0.
                        // If width is 0, the slice is empty.
                        
                        // Let's use the parameters to construct the slices.
                        
                        // tdata
                        r_tdata <= fifo_mem[fifo_rptr][S_DATA_WIDTH-1:0];
                        
                        // tlast
                        r_tlast <= fifo_mem[fifo_rptr][S_DATA_WIDTH];
                        
                        // tid
                        r_tid <= fifo_mem[fifo_rptr][S_DATA_WIDTH+1 : S_DATA_WIDTH+ID_WIDTH];
                        
                        // dest
                        r_dest <= fifo_mem[fifo_rptr][S_DATA_WIDTH+ID_WIDTH+1 : S_DATA_WIDTH+ID_WIDTH+DEST_WIDTH];
                        
                        // user
                        r_user <= fifo_mem[fifo_rptr][S_DATA_WIDTH+ID_WIDTH+DEST_WIDTH+1 : S_DATA_WIDTH+ID_WIDTH+DEST_WIDTH+USER_WIDTH];
                    end
                end
            end
            
            // Width Conversion Logic
