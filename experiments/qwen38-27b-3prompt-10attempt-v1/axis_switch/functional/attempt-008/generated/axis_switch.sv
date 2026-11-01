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
    wire [S_COUNT-1:0] s_tvalid_int;
    wire [S_COUNT-1:0] s_tready_int;
    wire [S_COUNT-1:0] s_tlast_int;
    wire [S_COUNT-1:0] s_tuser_int;
    wire [S_COUNT*DATA_WIDTH-1:0] s_tdata_int;
    wire [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_int;
    wire [S_COUNT*S_ID_WIDTH-1:0] s_tid_int;
    wire [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_int;

    wire [M_COUNT-1:0] m_tvalid_int;
    wire [M_COUNT-1:0] m_tready_int;
    wire [M_COUNT-1:0] m_tlast_int;
    wire [M_COUNT-1:0] m_tuser_int;
    wire [M_COUNT*DATA_WIDTH-1:0] m_tdata_int;
    wire [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_int;
    wire [M_COUNT*M_ID_WIDTH-1:0] m_tid_int;
    wire [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_int;

    // Source side register
    generate
        if (S_REG_TYPE != 0) begin : gen_s_reg
            reg [S_COUNT-1:0] s_tvalid_reg;
            reg [S_COUNT-1:0] s_tlast_reg;
            reg [S_COUNT-1:0] s_tuser_reg;
            reg [S_COUNT*DATA_WIDTH-1:0] s_tdata_reg;
            reg [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_reg;
            reg [S_COUNT*S_ID_WIDTH-1:0] s_tid_reg;
            reg [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_reg;

            integer i;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    s_tvalid_reg <= {S_COUNT{1'b0}};
                    s_tlast_reg <= {S_COUNT{1'b0}};
                    s_tuser_reg <= {S_COUNT{1'b0}};
                    s_tdata_reg <= {S_COUNT*DATA_WIDTH{1'b0}};
                    s_tkeep_reg <= {S_COUNT*KEEP_WIDTH{1'b0}};
                    s_tid_reg <= {S_COUNT*S_ID_WIDTH{1'b0}};
                    s_tdest_reg <= {S_COUNT*S_DEST_WIDTH{1'b0}};
                end else begin
                    for (i = 0; i < S_COUNT; i = i + 1) begin
                        if (s_axis_tvalid[i] && s_tready_int[i]) begin
                            s_tvalid_reg[i] <= 1'b1;
                            s_tlast_reg[i] <= s_axis_tlast[i];
                            s_tuser_reg[i] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                            s_tdata_reg[i*DATA_WIDTH +: DATA_WIDTH] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                            s_tkeep_reg[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                            s_tid_reg[i*S_ID_WIDTH +: S_ID_WIDTH] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                            s_tdest_reg[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                        end else if (s_tready_int[i]) begin
                            s_tvalid_reg[i] <= s_axis_tvalid[i];
                            s_tlast_reg[i] <= s_axis_tlast[i];
                            s_tuser_reg[i] <= s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];
                            s_tdata_reg[i*DATA_WIDTH +: DATA_WIDTH] <= s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                            s_tkeep_reg[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                            s_tid_reg[i*S_ID_WIDTH +: S_ID_WIDTH] <= s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                            s_tdest_reg[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                        end
                    end
                end
            end

            assign s_tvalid_int = s_tvalid_reg;
            assign s_tlast_int = s_tlast_reg;
            assign s_tuser_int = s_tuser_reg;
            assign s_tdata_int = s_tdata_reg;
            assign s_tkeep_int = s_tkeep_reg;
            assign s_tid_int = s_tid_reg;
            assign s_tdest_int = s_tdest_reg;
        end else begin : gen_s_no_reg
            assign s_tvalid_int = s_axis_tvalid;
            assign s_tlast_int = s_axis_tlast;
            assign s_tuser_int = s_axis_tuser;
            assign s_tdata_int = s_axis_tdata;
            assign s_tkeep_int = s_axis_tkeep;
            assign s_tid_int = s_axis_tid;
            assign s_tdest_int = s_axis_tdest;
        end
    endgenerate

    // Destination side register
    generate
        if (M_REG_TYPE != 0) begin : gen_m_reg
            reg [M_COUNT-1:0] m_tvalid_reg;
            reg [M_COUNT-1:0] m_tlast_reg;
            reg [M_COUNT-1:0] m_tuser_reg;
            reg [M_COUNT*DATA_WIDTH-1:0] m_tdata_reg;
            reg [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_reg;
            reg [M_COUNT*M_ID_WIDTH-1:0] m_tid_reg;
            reg [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_reg;

            integer j;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    m_tvalid_reg <= {M_COUNT{1'b0}};
                    m_tlast_reg <= {M_COUNT{1'b0}};
                    m_tuser_reg <= {M_COUNT{1'b0}};
                    m_tdata_reg <= {M_COUNT*DATA_WIDTH{1'b0}};
                    m_tkeep_reg <= {M_COUNT*KEEP_WIDTH{1'b0}};
                    m_tid_reg <= {M_COUNT*M_ID_WIDTH{1'b0}};
                    m_tdest_reg <= {M_COUNT*M_DEST_WIDTH{1'b0}};
                end else begin
                    for (j = 0; j < M_COUNT; j = j + 1) begin
                        if (m_tvalid_int[j] && m_tready_int[j]) begin
                            m_tvalid_reg[j] <= 1'b1;
                            m_tlast_reg[j] <= m_tlast_int[j];
                            m_tuser_reg[j] <= m_tuser_int[j];
                            m_tdata_reg[j*DATA_WIDTH +: DATA_WIDTH] <= m_tdata_int[j*DATA_WIDTH +: DATA_WIDTH];
                            m_tkeep_reg[j*KEEP_WIDTH +: KEEP_WIDTH] <= m_tkeep_int[j*KEEP_WIDTH +: KEEP_WIDTH];
                            m_tid_reg[j*M_ID_WIDTH +: M_ID_WIDTH] <= m_tid_int[j*M_ID_WIDTH +: M_ID_WIDTH];
                            m_tdest_reg[j*M_DEST_WIDTH +: M_DEST_WIDTH] <= m_tdest_int[j*M_DEST_WIDTH +: M_DEST_WIDTH];
                        end else if (m_tready_int[j]) begin
                            m_tvalid_reg[j] <= m_tvalid_int[j];
                            m_tlast_reg[j] <= m_tlast_int[j];
                            m_tuser_reg[j] <= m_tuser_int[j];
                            m_tdata_reg[j*DATA_WIDTH +: DATA_WIDTH] <= m_tdata_int[j*DATA_WIDTH +: DATA_WIDTH];
                            m_tkeep_reg[j*KEEP_WIDTH +: KEEP_WIDTH] <= m_tkeep_int[j*KEEP_WIDTH +: KEEP_WIDTH];
                            m_tid_reg[j*M_ID_WIDTH +: M_ID_WIDTH] <= m_tid_int[j*M_ID_WIDTH +: M_ID_WIDTH];
                            m_tdest_reg[j*M_DEST_WIDTH +: M_DEST_WIDTH] <= m_tdest_int[j*M_DEST_WIDTH +: M_DEST_WIDTH];
                        end
                    end
                end
            end

            assign m_tvalid_int = m_tvalid_reg;
            assign m_tlast_int = m_tlast_reg;
            assign m_tuser_int = m_tuser_reg;
            assign m_tdata_int = m_tdata_reg;
            assign m_tkeep_int = m_tkeep_reg;
            assign m_tid_int = m_tid_reg;
            assign m_tdest_int = m_tdest_reg;
        end else begin : gen_m_no_reg
            assign m_tvalid_int = m_axis_tvalid;
            assign m_tlast_int = m_axis_tlast;
            assign m_tuser_int = m_axis_tuser;
            assign m_tdata_int = m_axis_tdata;
            assign m_tkeep_int = m_axis_tkeep;
            assign m_tid_int = m_axis_tid;
            assign m_tdest_int = m_axis_tdest;
        end
    endgenerate

    // Arbitration logic
    // For each destination, determine which source is granted
    wire [M_COUNT-1:0][S_COUNT-1:0] grant;
    wire [M_COUNT-1:0] m_tready_eff;
    wire [M_COUNT-1:0] m_tvalid_eff;

    // Effective ready and valid for internal use
    assign m_tready_eff = m_tready_int;
    assign m_tvalid_eff = m_tvalid_int;

    // For each destination j, find the source i that is granted
    // A source i can send to destination j if:
    // 1. s_tvalid_int[i] is high
    // 2. s_tdest_int[i] points to j (within M_BASE to M_TOP range)
    // 3. M_CONNECT[j][i] is high
    // 4. m_tready_eff[j] is high (for the destination to accept)

    // We need to arbitrate among sources that want the same destination
    // Let's define for each destination j, a vector of sources that want to send to j
    wire [M_COUNT-1:0][S_COUNT-1:0] want;
    
    genvar gj;
    genvar gi;
    generate
        for (gj = 0; gj < M_COUNT; gj = gj + 1) begin : gen_dest
            for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_src
                // Check if source gi wants to send to destination gj
                // tdest is S_DEST_WIDTH bits, we need to check if it maps to gj
                // The destination index is s_tdest_int[gi*S_DEST_WIDTH +: S_DEST_WIDTH]
                // We need to check if this destination is within [M_BASE, M_TOP] and equals gj
                // Actually, the tdest value should be the destination index
                // Let's assume tdest is the destination index directly
                // But we need to handle the M_BASE and M_TOP offset
                // The actual destination index is tdest - M_BASE, and it should be in [0, M_TOP-M_BASE]
                // And it should equal gj
                
                wire [S_DEST_WIDTH-1:0] dest_val = s_tdest_int[gi*S_DEST_WIDTH +: S_DEST_WIDTH];
                wire [S_DEST_WIDTH-1:0] dest_offset = dest_val - M_BASE[S_DEST_WIDTH-1:0];
                wire in_range = (dest_val >= M_BASE[S_DEST_WIDTH-1:0]) && (dest_val <= M_TOP[S_DEST_WIDTH-1:0]);
                wire matches = (dest_offset == gj[S_DEST_WIDTH-1:0]);
                
                assign want[gj][gi] = s_tvalid_int[gi] && in_range && matches && M_CONNECT[gj][gi];
            end
        end
    endgenerate

    // Now arbitrate for each destination
    // If ARB_TYPE_ROUND_ROBIN is set, use round-robin
    // Otherwise, use fixed priority (LSB high priority if ARB_LSB_HIGH_PRIORITY, else MSB high)
    
    // For round-robin, we need to track the last granted source for each destination
    reg [M_COUNT-1:0][$clog2(S_COUNT)-1:0] last_grant;
    
    integer k;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (k = 0; k < M_COUNT; k = k + 1) begin
                last_grant[k] <= 0;
            end
        end else begin
            for (k = 0; k < M_COUNT; k = k + 1) begin
                if (grant[k] != 0) begin
                    // Find the index of the granted source
                    for (gi = 0; gi < S_COUNT; gi = gi + 1) begin
                        if (grant[k][gi]) begin
                            last_grant[k] <= gi[$clog2(S_COUNT)-1:0];
                        end
                    end
                end
            end
        end
    end

    // Generate grant signals
    generate
        for (gj = 0; gj < M_COUNT; gj = gj + 1) begin : gen_grant
            if (ARB_TYPE_ROUND_ROBIN) begin : gen_rr
                // Round-robin arbitration
                // Create a rotated version of the want vector starting from last_grant[gj]+1
                wire [S_COUNT-1:0] want_rr;
                wire [S_COUNT-1:0] want_rotated;
                
                // Rotate want so that the position after last_grant is at LSB
                // If last_grant is L, then we want to start checking from L+1
                // We can do this by rotating left by (L+1) positions
                // But we need to handle the wrap-around
                
                // Let's use a different approach:
                // Create two vectors: one for sources after last_grant, one for sources before
                // And prioritize the "after" group first
                
                wire [S_COUNT-1:0] want_after;
                wire [S_COUNT-1:0] want_before;
                
                for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_rr_split
                    if (gi > last_grant[gj]) begin
                        assign want_after[gi] = want[gj][gi];
                    end else begin
                        assign want_after[gi] = 1'b0;
                    end
                    if (gi <= last_grant[gj]) begin
                        assign want_before[gi] = want[gj][gi];
                    end else begin
                        assign want_before[gi] = 1'b0;
                    end
                end
                
                // Find the lowest set bit in want_after (highest priority in round-robin)
                wire [S_COUNT-1:0] grant_after;
                wire [S_COUNT-1:0] grant_before;
                
                // For LSB high priority, the lowest index has highest priority
                // So we want the lowest set bit
                assign grant_after = want_after & ~(want_after - 1'b1);
                assign grant_before = want_before & ~(want_before - 1'b1);
                
                // If there's a grant in the "after" group, use it; otherwise use "before"
                assign grant[gj] = (|grant_after) ? grant_after : grant_before;
            end else begin : gen_fixed
                // Fixed priority arbitration
                if (ARB_LSB_HIGH_PRIORITY) begin : gen_lsb_hp
                    // LSB has highest priority, so lowest index wins
                    assign grant[gj] = want[gj] & ~(want[gj] - 1'b1);
                end else begin : gen_msb_hp
                    // MSB has highest priority, so highest index wins
                    // We need to find the highest set bit
                    // This is more complex, let's use a priority encoder
                    wire [S_COUNT-1:0] grant_msb;
                    for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_msb_enc
                        if (gi == 0) begin
                            assign grant_msb[0] = want[gj][0];
                        end else begin
                            assign grant_msb[gi] = want[gj][gi] & ~(want[gj][gi-1:0] != 0);
                        end
                    end
                    assign grant[gj] = grant_msb;
                end
            end
        end
    endgenerate

    // Now, a source is ready if it is granted to a destination that is ready
    // s_tready_int[i] = OR over all j of (grant[j][i] && m_tready_eff[j])
    
    genvar si;
    generate
        for (si = 0; si < S_COUNT; si = si + 1) begin : gen_s_ready
            wire [M_COUNT-1:0] ready_for_src;
            for (gj = 0; gj < M_COUNT; gj = gj + 1) begin : gen_s_ready_dest
                assign ready_for_src[gj] = grant[gj][si] && m_tready_eff[gj];
            end
            assign s_tready_int[si] = |ready_for_src;
        end
    endgenerate

    // Now, for each destination, determine which source is driving it
    // m_tvalid_int[j] = OR over all i of (grant[j][i] && s_tvalid_int[i])
    // But since grant[j][i] already implies s_tvalid_int[i], we just need:
    // m_tvalid_int[j] = |grant[j]
    
    for (gj = 0; gj < M_COUNT; gj = gj + 1) begin : gen_m_valid
        assign m_tvalid_int[gj] = |grant[gj];
    end

    // Mux the data from the granted source to each destination
    generate
        for (gj = 0; gj < M_COUNT; gj = gj + 1) begin : gen_m_mux
            // Data
            for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_m_data
                if (gi == 0) begin
                    assign m_tdata_int[gj*DATA_WIDTH +: DATA_WIDTH] = grant[gj][0] ? s_tdata_int[0*DATA_WIDTH +: DATA_WIDTH] : {DATA_WIDTH{1'b0}};
                end else begin
                    assign m_tdata_int[gj*DATA_WIDTH +: DATA_WIDTH] = grant[gj][gi] ? s_tdata_int[gi*DATA_WIDTH +: DATA_WIDTH] : m_tdata_int[gj*DATA_WIDTH +: DATA_WIDTH];
                end
            end
            
            // Keep
            if (KEEP_ENABLE) begin : gen_m_keep
                for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_m_keep_mux
                    if (gi == 0) begin
                        assign m_tkeep_int[gj*KEEP_WIDTH +: KEEP_WIDTH] = grant[gj][0] ? s_tkeep_int[0*KEEP_WIDTH +: KEEP_WIDTH] : {KEEP_WIDTH{1'b0}};
                    end else begin
                        assign m_tkeep_int[gj*KEEP_WIDTH +: KEEP_WIDTH] = grant[gj][gi] ? s_tkeep_int[gi*KEEP_WIDTH +: KEEP_WIDTH] : m_tkeep_int[gj*KEEP_WIDTH +: KEEP_WIDTH];
                    end
                end
            end
            
            // Last
            for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_m_last
                if (gi == 0) begin
                    assign m_tlast_int[gj] = grant[gj][0] ? s_tlast_int[0] : 1'b0;
                end else begin
                    assign m_tlast_int[gj] = grant[gj][gi] ? s_tlast_int[gi] : m_tlast_int[gj];
                end
            end
            
            // User
            if (USER_ENABLE) begin : gen_m_user
                for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_m_user_mux
                    if (gi == 0) begin
                        assign m_tuser_int[gj] = grant[gj][0] ? s_tuser_int[0] : 1'b0;
                    end else begin
                        assign m_tuser_int[gj] = grant[gj][gi] ? s_tuser_int[gi] : m_tuser_int[gj];
                    end
                end
            end
            
            // TID
            if (ID_ENABLE) begin : gen_m_tid
                for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_m_tid_mux
                    if (gi == 0) begin
                        assign m_tid_int[gj*M_ID_WIDTH +: M_ID_WIDTH] = grant[gj][0] ? s_tid_int[0*S_ID_WIDTH +: S_ID_WIDTH] : {M_ID_WIDTH{1'b0}};
                    end else begin
                        assign m_tid_int[gj*M_ID_WIDTH +: M_ID_WIDTH] = grant[gj][gi] ? s_tid_int[gi*S_ID_WIDTH +: S_ID_WIDTH] : m_tid_int[gj*M_ID_WIDTH +: M_ID_WIDTH];
                    end
                end
            end
            
            // TDEST
            for (gi = 0; gi < S_COUNT; gi = gi + 1) begin : gen_m_tdest
                if (gi == 0) begin
                    assign m_tdest_int[gj*M_DEST_WIDTH +: M_DEST_WIDTH] = grant[gj][0] ? s_tdest_int[0*S_DEST_WIDTH +: S_DEST_WIDTH] : {M_DEST_WIDTH{1'b0}};
                end else begin
                    assign m_tdest_int[gj*M_DEST_WIDTH +: M_DEST_WIDTH] = grant[gj][gi] ? s_tdest_int[gi*S_DEST_WIDTH +: S_DEST_WIDTH] : m_tdest_int[gj*M_DEST_WIDTH +: M_DEST_WIDTH];
                end
            end
        end
    endgenerate

    // Assign output ports
    assign s_axis_tready = s_tready_int;
    assign m_axis_tdata = m_tdata_int;
    assign m_axis_tkeep = m_tkeep_int;
    assign m_axis_tvalid = m_tvalid_int;
    assign m_axis_tlast = m_tlast_int;
    assign m_axis_tid = m_tid_int;
    assign m_axis_tdest = m_tdest_int;
    assign m_axis_tuser = m_tuser_int;

endmodule
