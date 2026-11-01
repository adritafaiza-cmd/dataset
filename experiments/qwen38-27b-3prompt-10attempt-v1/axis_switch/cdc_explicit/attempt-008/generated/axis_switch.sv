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

    // Input register stage
    generate
        if (S_REG_TYPE != 0) begin : gen_s_reg
            reg [S_COUNT-1:0] s_tvalid_r;
            reg [S_COUNT-1:0] s_tlast_r;
            reg [S_COUNT-1:0] s_tuser_r;
            reg [S_COUNT*DATA_WIDTH-1:0] s_tdata_r;
            reg [S_COUNT*KEEP_WIDTH-1:0] s_tkeep_r;
            reg [S_COUNT*S_ID_WIDTH-1:0] s_tid_r;
            reg [S_COUNT*S_DEST_WIDTH-1:0] s_tdest_r;

            integer i;
            for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_reg_i
                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        s_tvalid_r[i] <= 1'b0;
                        s_tlast_r[i] <= 1'b0;
                        s_tuser_r[i] <= 1'b0;
                        s_tdata_r[i*DATA_WIDTH +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
                        s_tkeep_r[i*KEEP_WIDTH +: KEEP_WIDTH] <= {KEEP_WIDTH{1'b0}};
                        s_tid_r[i*S_ID_WIDTH +: S_ID_WIDTH] <= {S_ID_WIDTH{1'b0}};
                        s_tdest_r[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= {S_DEST_WIDTH{1'b0}};
                    end else begin
                        if (s_tvalid[i] && s_tready_int[i]) begin
                            s_tvalid_r[i] <= 1'b1;
                            s_tlast_r[i] <= s_tlast[i];
                            s_tuser_r[i] <= s_tuser[i*USER_WIDTH +: USER_WIDTH];
                            s_tdata_r[i*DATA_WIDTH +: DATA_WIDTH] <= s_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                            s_tkeep_r[i*KEEP_WIDTH +: KEEP_WIDTH] <= s_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                            s_tid_r[i*S_ID_WIDTH +: S_ID_WIDTH] <= s_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                            s_tdest_r[i*S_DEST_WIDTH +: S_DEST_WIDTH] <= s_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                        end else if (s_tvalid_r[i] && s_tready_int[i]) begin
                            s_tvalid_r[i] <= 1'b0;
                        end
                    end
                end
            end

            assign s_tvalid_int = s_tvalid_r;
            assign s_tlast_int = s_tlast_r;
            assign s_tuser_int = s_tuser_r;
            assign s_tdata_int = s_tdata_r;
            assign s_tkeep_int = s_tkeep_r;
            assign s_tid_int = s_tid_r;
            assign s_tdest_int = s_tdest_r;
            assign s_tready_int = s_tvalid_r | ~s_tvalid;
        end else begin : gen_s_no_reg
            assign s_tvalid_int = s_tvalid;
            assign s_tlast_int = s_tlast;
            assign s_tuser_int = s_tuser;
            assign s_tdata_int = s_tdata;
            assign s_tkeep_int = s_tkeep;
            assign s_tid_int = s_tid;
            assign s_tdest_int = s_tdest;
            assign s_tready_int = s_tready;
        end
    endgenerate

    // Output register stage
    generate
        if (M_REG_TYPE != 0) begin : gen_m_reg
            reg [M_COUNT-1:0] m_tvalid_r;
            reg [M_COUNT-1:0] m_tlast_r;
            reg [M_COUNT-1:0] m_tuser_r;
            reg [M_COUNT*DATA_WIDTH-1:0] m_tdata_r;
            reg [M_COUNT*KEEP_WIDTH-1:0] m_tkeep_r;
            reg [M_COUNT*M_ID_WIDTH-1:0] m_tid_r;
            reg [M_COUNT*M_DEST_WIDTH-1:0] m_tdest_r;

            integer j;
            for (j = 0; j < M_COUNT; j = j + 1) begin : gen_m_reg_j
                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        m_tvalid_r[j] <= 1'b0;
                        m_tlast_r[j] <= 1'b0;
                        m_tuser_r[j] <= 1'b0;
                        m_tdata_r[j*DATA_WIDTH +: DATA_WIDTH] <= {DATA_WIDTH{1'b0}};
                        m_tkeep_r[j*KEEP_WIDTH +: KEEP_WIDTH] <= {KEEP_WIDTH{1'b0}};
                        m_tid_r[j*M_ID_WIDTH +: M_ID_WIDTH] <= {M_ID_WIDTH{1'b0}};
                        m_tdest_r[j*M_DEST_WIDTH +: M_DEST_WIDTH] <= {M_DEST_WIDTH{1'b0}};
                    end else begin
                        if (m_tvalid_int[j] && m_tready_int[j]) begin
                            m_tvalid_r[j] <= 1'b1;
                            m_tlast_r[j] <= m_tlast_int[j];
                            m_tuser_r[j] <= m_tuser_int[j];
                            m_tdata_r[j*DATA_WIDTH +: DATA_WIDTH] <= m_tdata_int[j*DATA_WIDTH +: DATA_WIDTH];
                            m_tkeep_r[j*KEEP_WIDTH +: KEEP_WIDTH] <= m_tkeep_int[j*KEEP_WIDTH +: KEEP_WIDTH];
                            m_tid_r[j*M_ID_WIDTH +: M_ID_WIDTH] <= m_tid_int[j*M_ID_WIDTH +: M_ID_WIDTH];
                            m_tdest_r[j*M_DEST_WIDTH +: M_DEST_WIDTH] <= m_tdest_int[j*M_DEST_WIDTH +: M_DEST_WIDTH];
                        end else if (m_tvalid_r[j] && m_tready_int[j]) begin
                            m_tvalid_r[j] <= 1'b0;
                        end
                    end
                end
            end

            assign m_tvalid = m_tvalid_r;
            assign m_tlast = m_tlast_r;
            assign m_tuser = m_tuser_r;
            assign m_tdata = m_tdata_r;
            assign m_tkeep = m_tkeep_r;
            assign m_tid = m_tid_r;
            assign m_tdest = m_tdest_r;
            assign m_tready_int = m_tvalid_r | ~m_tready;
        end else begin : gen_m_no_reg
            assign m_tvalid = m_tvalid_int;
            assign m_tlast = m_tlast_int;
            assign m_tuser = m_tuser_int;
            assign m_tdata = m_tdata_int;
            assign m_tkeep = m_tkeep_int;
            assign m_tid = m_tid_int;
            assign m_tdest = m_tdest_int;
            assign m_tready_int = m_tready;
        end
    endgenerate

    // Switch core
    // For each output port, determine which input is selected
    // We need to handle arbitration for each output port

    // Internal signals for the switch fabric
    wire [S_COUNT-1:0] s_tvalid_core;
    wire [S_COUNT-1:0] s_tready_core;
    wire [M_COUNT-1:0] m_tvalid_core;
    wire [M_COUNT-1:0] m_tready_core;

    assign s_tvalid_core = s_tvalid_int;
    assign m_tready_core = m_tready_int;

    // For each output port m, we need to select one input port s
    // The selection is based on tdest and arbitration

    // Let's define the request and grant signals
    // For each output m, an input s requests if s_tvalid[s] && s_tdest[s] == m
    // We need to arbitrate among all requesting inputs for each output

    // Round-robin arbitration state
    reg [S_COUNT-1:0] rr_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_state <= {S_COUNT{1'b0}};
        end else begin
            // Update round-robin state when a grant is made
            // For simplicity, we'll update the state based on the highest priority granted input
            // This is a simplified approach; a full implementation would track per-output state
            // For now, we'll use a simple priority encoder with round-robin bias
        end
    end

    // Generate the switch fabric
    // For each output port, we'll use a priority encoder to select the input

    // Let's create a helper function to get the selected input for each output
    // We'll use a generate block to create the arbitration logic for each output

    // For each output m, collect the requests from all inputs
    // request[m][s] = s_tvalid[s] && (s_tdest[s] == m)

    // We'll use a simple approach: for each output, use a priority encoder
    // with round-robin bias

    // Let's define the grant signals
    wire [M_COUNT-1:0][S_COUNT-1:0] grant;

    // For each output port
    genvar m;
    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_out
            // Request vector for this output
            wire [S_COUNT-1:0] req;
            integer s;
            for (s = 0; s < S_COUNT; s = s + 1) begin : gen_req
                assign req[s] = s_tvalid_core[s] && (s_tdest_core[s*S_DEST_WIDTH +: S_DEST_WIDTH] == m) && M_CONNECT[m*S_COUNT + s];
            end

            // Arbitration
            // If round-robin, use the rr_state to bias the priority
            // For simplicity, we'll use a fixed priority with LSB high priority
            // and add round-robin by rotating the request vector

            wire [S_COUNT-1:0] req_rotated;
            wire [S_COUNT-1:0] grant_sel;

            // Simple priority encoder: select the lowest set bit
            // This gives LSB high priority
            assign grant_sel = req & ~(req - 1'b1);

            // For round-robin, we need to rotate based on rr_state
            // This is a simplified implementation
            if (ARB_TYPE_ROUND_ROBIN) begin : gen_rr
                // Rotate the request vector based on rr_state
                // For a proper round-robin, we'd need to track the last granted input
                // For now, we'll use a simple approach
                assign req_rotated = req;
            end else begin : gen_fixed
                assign req_rotated = req;
            end

            // Select the grant
            assign grant[m] = grant_sel;
        end
    endgenerate

    // Now, for each input s, it is ready if it is granted by its destination output
    // s_tready[s] = grant[s_tdest[s]][s]

    // For each input s
    genvar s;
    generate
        for (s = 0; s < S_COUNT; s = s + 1) begin : gen_in
            // Get the destination
            wire [S_DEST_WIDTH-1:0] dest = s_tdest_core[s*S_DEST_WIDTH +: S_DEST_WIDTH];

            // Check if this input is granted by its destination
            wire granted = grant[dest][s];

            // The input is ready if it is granted
            assign s_tready_core[s] = granted;
        end
    endgenerate

    // Now, for each output m, we need to mux the data from the granted input
    // m_tvalid[m] = |grant[m]
    // m_tdata[m] = mux of s_tdata based on grant[m]

    // For each output m
    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_out_data
            // Valid
            assign m_tvalid_core[m] = |grant[m];

            // Data
            reg [DATA_WIDTH-1:0] data_sel;
            integer s;
            for (s = 0; s < S_COUNT; s = s + 1) begin : gen_data_sel
                if (grant[m][s]) begin
                    assign data_sel = s_tdata_core[s*DATA_WIDTH +: DATA_WIDTH];
                end
            end
            assign m_tdata_core[m*DATA_WIDTH +: DATA_WIDTH] = data_sel;

            // Keep
            if (KEEP_ENABLE) begin : gen_keep
                reg [KEEP_WIDTH-1:0] keep_sel;
                integer s;
                for (s = 0; s < S_COUNT; s = s + 1) begin : gen_keep_sel
                    if (grant[m][s]) begin
                        assign keep_sel = s_tkeep_core[s*KEEP_WIDTH +: KEEP_WIDTH];
                    end
                end
                assign m_tkeep_core[m*KEEP_WIDTH +: KEEP_WIDTH] = keep_sel;
            end

            // Last
            reg last_sel;
            integer s;
            for (s = 0; s < S_COUNT; s = s + 1) begin : gen_last_sel
                if (grant[m][s]) begin
                    assign last_sel = s_tlast_core[s];
                end
            end
            assign m_tlast_core[m] = last_sel;

            // User
            if (USER_ENABLE) begin : gen_user
                reg [USER_WIDTH-1:0] user_sel;
                integer s;
                for (s = 0; s < S_COUNT; s = s + 1) begin : gen_user_sel
                    if (grant[m][s]) begin
                        assign user_sel = s_tuser_core[s*USER_WIDTH +: USER_WIDTH];
                    end
                end
                assign m_tuser_core[m*USER_WIDTH +: USER_WIDTH] = user_sel;
            end

            // TID
            if (ID_ENABLE) begin : gen_tid
                reg [M_ID_WIDTH-1:0] tid_sel;
                integer s;
                for (s = 0; s < S_COUNT; s = s + 1) begin : gen_tid_sel
                    if (grant[m][s]) begin
                        if (UPDATE_TID) begin
                            // Update TID with source ID
                            assign tid_sel = {s, s_tid_core[s*S_ID_WIDTH +: S_ID_WIDTH]};
                        end else begin
                            assign tid_sel = s_tid_core[s*S_ID_WIDTH +: S_ID_WIDTH];
                        end
                    end
                end
                assign m_tid_core[m*M_ID_WIDTH +: M_ID_WIDTH] = tid_sel;
            end

            // TDEST
            if (M_DEST_WIDTH > 0) begin : gen_tdest
                reg [M_DEST_WIDTH-1:0] tdest_sel;
                integer s;
                for (s = 0; s < S_COUNT; s = s + 1) begin : gen_tdest_sel
                    if (grant[m][s]) begin
                        assign tdest_sel = m;
                    end
                end
                assign m_tdest_core[m*M_DEST_WIDTH +: M_DEST_WIDTH] = tdest_sel;
            end
        end
    endgenerate

    // Connect the core signals to the registered/unregistered signals
    assign s_tready = s_tready_core;
    assign m_tvalid_int = m_tvalid_core;
    assign m_tlast_int = m_tlast_core;
    assign m_tuser_int = m_tuser_core;
    assign m_tdata_int = m_tdata_core;
    assign m_tkeep_int = m_tkeep_core;
    assign m_tid_int = m_tid_core;
    assign m_tdest_int = m_tdest_core;

endmodule
