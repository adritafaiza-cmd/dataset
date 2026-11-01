module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    /*
     * AXI Stream inputs
     */
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    /*
     * AXI Stream outputs
     */
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    // Internal signals
    wire [S_COUNT-1:0] s_valid;
    wire [S_COUNT-1:0] s_ready;
    wire [S_COUNT-1:0] s_fire;
    
    wire [M_COUNT-1:0] m_valid;
    wire [M_COUNT-1:0] m_ready;
    wire [M_COUNT-1:0] m_fire;
    
    // Per-input destination
    wire [S_COUNT-1:0][S_DEST_WIDTH-1:0] s_dest;
    // Per-input data
    wire [S_COUNT-1:0][DATA_WIDTH-1:0] s_data;
    // Per-input keep
    wire [S_COUNT-1:0][KEEP_WIDTH-1:0] s_keep;
    // Per-input last
    wire [S_COUNT-1:0] s_last;
    // Per-input tid
    wire [S_COUNT-1:0][S_ID_WIDTH-1:0] s_id;
    // Per-input user
    wire [S_COUNT-1:0][USER_WIDTH-1:0] s_user;

    // Unpack input signals
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : unpack_s
            assign s_data[i] = s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
            assign s_keep[i] = s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
            assign s_last[i] = s_axis_tlast[i];
            assign s_id[i]   = s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
            assign s_dest[i] = s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
            assign s_user[i] = s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
        end
    endgenerate

    // Determine which inputs are requesting which outputs
    // req[m][s] = 1 if input s is valid and wants output m
    wire [M_COUNT-1:0][S_COUNT-1:0] req;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_req_m
            for (genvar j = 0; j < S_COUNT; j = j + 1) begin : gen_req_s
                assign req[i][j] = s_axis_tvalid[j] && 
                                   (s_dest[j] == i) && 
                                   M_CONNECT[i*S_COUNT + j];
            end
        end
    endgenerate

    // Arbitration per output
    // For each output m, select one input s
    wire [M_COUNT-1:0][S_COUNT-1:0] grant;
    wire [M_COUNT-1:0] arb_valid;
    
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_arb
            // Priority encoder or round-robin
            wire [S_COUNT-1:0] req_m = req[i];
            wire [S_COUNT-1:0] grant_m;
            wire arb_valid_m;
            
            if (ARB_TYPE_ROUND_ROBIN) begin : rr_arb
                // Round-robin arbitration
                // We need to track the last granted input for each output
                reg [S_COUNT-1:0] last_grant;
                
                always @(posedge clk or posedge rst) begin
                    if (rst)
                        last_grant <= {S_COUNT{1'b0}};
                    else if (arb_valid_m && grant_m != {S_COUNT{1'b0}})
                        last_grant <= grant_m;
                end
                
                // Rotate the request vector so that the last granted input has lowest priority
                // Actually, standard round-robin: give priority to inputs after the last granted one
                // Let's use a simpler approach: priority encoder with rotation
                
                // For simplicity, we'll use a fixed priority if round-robin is complex
                // But let's implement proper round-robin
                // We'll use a priority encoder that starts from last_grant+1
                
                wire [S_COUNT-1:0] rotated_req;
                integer k;
                // This is getting complex. Let's use a simpler approach:
                // If ARB_TYPE_ROUND_ROBIN, use round-robin, else use fixed priority
                
                // For now, let's implement fixed priority and note that round-robin needs state
                // Actually, let's implement a basic round-robin using a counter
                
                reg [$clog2(S_COUNT)-1:0] rr_ptr;
                
                always @(posedge clk or posedge rst) begin
                    if (rst)
                        rr_ptr <= 0;
                    else if (arb_valid_m)
                        rr_ptr <= grant_m;
                end
                
                // Generate rotated request
                // Priority: start from rr_ptr, go around
                wire [S_COUNT-1:0] prio_req;
                for (genvar p = 0; p < S_COUNT; p = p + 1) begin : gen_prio
                    assign prio_req[p] = req_m[(rr_ptr + p) % S_COUNT];
                end
                
                // Priority encoder: find first set bit
                assign grant_m = (prio_req != 0) ? 
                    (1 << find_first_set(prio_req)) : {S_COUNT{1'b0}};
                assign arb_valid_m = (prio_req != 0);
                
                // Map back to original index
                wire [S_COUNT-1:0] grant_orig;
                for (genvar g = 0; g < S_COUNT; g = g + 1) begin : gen_grant_map
                    assign grant_orig[g] = grant_m[(g - rr_ptr + S_COUNT) % S_COUNT];
                end
                
                assign grant[i] = grant_orig;
                assign arb_valid[i] = arb_valid_m;
            end else begin : fixed_arb
                // Fixed priority: LSB high priority
                assign grant_m = (req_m != 0) ? 
                    (1 << find_first_set(req_m)) : {S_COUNT{1'b0}};
                assign arb_valid_m = (req_m != 0);
                assign grant[i] = grant_m;
                assign arb_valid[i] = arb_valid_m;
            end
        end
    endgenerate

    // Helper function to find first set bit
    function integer find_first_set;
        input [S_COUNT-1:0] vec;
        integer idx;
        begin
            find_first_set = 0;
            for (idx = 0; idx < S_COUNT; idx = idx + 1) begin
                if (vec[idx]) begin
                    find_first_set = idx;
                    break;
                end
            end
        end
    endfunction

    // Generate s_axis_tready
    // Input s is ready if it is granted by its destination output and that output is ready
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_ready
            wire [M_COUNT-1:0] dest_ready;
            for (genvar d = 0; d < M_COUNT; d = d + 1) begin : gen_dest
                assign dest_ready[d] = m_ready[d] && grant[d][i];
            end
            assign s_ready[i] = |dest_ready;
        end
    endgenerate

    assign s_axis_tready = s_ready;

    // Generate m_axis_tvalid
    assign m_axis_tvalid = arb_valid;

    // Generate m_axis_tdata, m_axis_tkeep, m_axis_tlast, m_axis_tid, m_axis_tdest, m_axis_tuser
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_out
            // Find which input is granted to this output
            wire [S_COUNT-1:0] grant_m = grant[i];
            
            // Mux the data from the granted input
            wire [DATA_WIDTH-1:0] m_data;
            wire [KEEP_WIDTH-1:0] m_keep;
            wire m_last;
            wire [S_ID_WIDTH-1:0] m_id;
            wire [USER_WIDTH-1:0] m_user;
            
            for (genvar s = 0; s < S_COUNT; s = s + 1) begin : gen_mux
                assign m_data = grant_m[s] ? s_data[s] : m_data;
                assign m_keep = grant_m[s] ? s_keep[s] : m_keep;
                assign m_last = grant_m[s] ? s_last[s] : m_last;
                assign m_id   = grant_m[s] ? s_id[s] : m_id;
                assign m_user = grant_m[s] ? s_user[s] : m_user;
            end
            
            // Initialize to 0
            assign m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] = m_data;
            assign m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] = m_keep;
            assign m_axis_tlast[i] = m_last;
            
            // Handle TID
            if (UPDATE_TID) begin : update_tid
                // Update TID: replace destination field with output index
                // TID format: [S_ID_WIDTH-1:0] original ID, then $clog2(S_COUNT) bits for source
                // M_ID_WIDTH = S_ID_WIDTH + $clog2(S_COUNT)
                // We need to set the lower $clog2(S_COUNT) bits to the source index
                wire [$clog2(S_COUNT)-1:0] src_idx;
                for (genvar si = 0; si < S_COUNT; si = si + 1) begin : gen_src
                    assign src_idx = grant_m[si] ? si[$clog2(S_COUNT)-1:0] : src_idx;
                end
                assign m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] = {m_id, src_idx};
            end else begin : no_update_tid
                assign m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] = {m_id, {($clog2(S_COUNT)){1'b0}}};
            end
            
            // TDEST: set to output index
            assign m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] = i[M_DEST_WIDTH-1:0];
            
            // USER
            assign m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] = m_user;
        end
    endgenerate

endmodule
