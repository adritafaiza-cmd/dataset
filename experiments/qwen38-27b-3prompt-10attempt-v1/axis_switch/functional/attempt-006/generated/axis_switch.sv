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
    wire [S_COUNT-1:0] s_tvalid;
    wire [S_COUNT-1:0] s_tready;
    wire [S_COUNT-1:0] s_tlast;
    wire [S_COUNT*DATA_WIDTH-1:0] s_tdata;
    wire [S_COUNT*KEEP_WIDTH-1:0] s_tkeep;
    wire [S_COUNT*S_ID_WIDTH-1:0] s_tid;
    wire [S_COUNT*S_DEST_WIDTH-1:0] s_tdest;
    wire [S_COUNT*USER_WIDTH-1:0] s_tuser;

    wire [M_COUNT-1:0] m_tvalid;
    wire [M_COUNT-1:0] m_tready;
    wire [M_COUNT-1:0] m_tlast;
    wire [M_COUNT*DATA_WIDTH-1:0] m_tdata;
    wire [M_COUNT*KEEP_WIDTH-1:0] m_tkeep;
    wire [M_COUNT*M_ID_WIDTH-1:0] m_tid;
    wire [M_COUNT*M_DEST_WIDTH-1:0] m_tdest;
    wire [M_COUNT*USER_WIDTH-1:0] m_tuser;

    // Input registration
    generate
        if (S_REG_TYPE == 1) begin
            genvar i;
            for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_reg
                reg [DATA_WIDTH-1:0] s_tdata_reg;
                reg [KEEP_WIDTH-1:0] s_tkeep_reg;
                reg s_tvalid_reg;
                reg s_tlast_reg;
                reg [S_ID_WIDTH-1:0] s_tid_reg;
                reg [S_DEST_WIDTH-1:0] s_tdest_reg;
                reg [USER_WIDTH-1:0] s_tuser_reg;
                reg s_tready_reg;

                wire s_tvalid_in = s_axis_tvalid[i];
                wire s_tready_in = s_tready[i];
                wire s_tlast_in = s_axis_tlast[i];
                wire [DATA_WIDTH-1:0] s_tdata_in = s_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH];
                wire [KEEP_WIDTH-1:0] s_tkeep_in = s_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH];
                wire [S_ID_WIDTH-1:0] s_tid_in = s_axis_tid[i*S_ID_WIDTH +: S_ID_WIDTH];
                wire [S_DEST_WIDTH-1:0] s_tdest_in = s_axis_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH];
                wire [USER_WIDTH-1:0] s_tuser_in = s_axis_tuser[i*USER_WIDTH +: USER_WIDTH];

                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        s_tdata_reg <= {DATA_WIDTH{1'b0}};
                        s_tkeep_reg <= {KEEP_WIDTH{1'b0}};
                        s_tvalid_reg <= 1'b0;
                        s_tlast_reg <= 1'b0;
                        s_tid_reg <= {S_ID_WIDTH{1'b0}};
                        s_tdest_reg <= {S_DEST_WIDTH{1'b0}};
                        s_tuser_reg <= {USER_WIDTH{1'b0}};
                        s_tready_reg <= 1'b0;
                    end else begin
                        if (s_tvalid_in && s_tready_in) begin
                            s_tdata_reg <= s_tdata_in;
                            s_tkeep_reg <= s_tkeep_in;
                            s_tvalid_reg <= 1'b1;
                            s_tlast_reg <= s_tlast_in;
                            s_tid_reg <= s_tid_in;
                            s_tdest_reg <= s_tdest_in;
                            s_tuser_reg <= s_tuser_in;
                        end else if (s_tvalid_in) begin
                            s_tdata_reg <= s_tdata_in;
                            s_tkeep_reg <= s_tkeep_in;
                            s_tvalid_reg <= 1'b1;
                            s_tlast_reg <= s_tlast_in;
                            s_tid_reg <= s_tid_in;
                            s_tdest_reg <= s_tdest_in;
                            s_tuser_reg <= s_tuser_in;
                        end else if (s_tready_in) begin
                            s_tvalid_reg <= 1'b0;
                        end
                        s_tready_reg <= s_tready_in;
                    end
                end

                assign s_tdata[i*DATA_WIDTH +: DATA_WIDTH] = s_tdata_reg;
                assign s_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] = s_tkeep_reg;
                assign s_tvalid[i] = s_tvalid_reg;
                assign s_tlast[i] = s_tlast_reg;
                assign s_tid[i*S_ID_WIDTH +: S_ID_WIDTH] = s_tid_reg;
                assign s_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH] = s_tdest_reg;
                assign s_tuser[i*USER_WIDTH +: USER_WIDTH] = s_tuser_reg;
                assign s_axis_tready[i] = s_tready_reg;
            end
        end else begin
            assign s_tdata = s_axis_tdata;
            assign s_tkeep = s_axis_tkeep;
            assign s_tvalid = s_axis_tvalid;
            assign s_tlast = s_axis_tlast;
            assign s_tid = s_axis_tid;
            assign s_tdest = s_axis_tdest;
            assign s_tuser = s_axis_tuser;
            assign s_axis_tready = s_tready;
        end
    endgenerate

    // Output registration
    generate
        if (M_REG_TYPE == 1) begin
            genvar j;
            for (j = 0; j < M_COUNT; j = j + 1) begin : gen_m_reg
                reg [DATA_WIDTH-1:0] m_tdata_reg;
                reg [KEEP_WIDTH-1:0] m_tkeep_reg;
                reg m_tvalid_reg;
                reg m_tlast_reg;
                reg [M_ID_WIDTH-1:0] m_tid_reg;
                reg [M_DEST_WIDTH-1:0] m_tdest_reg;
                reg [USER_WIDTH-1:0] m_tuser_reg;
                reg m_tready_reg;

                wire m_tvalid_in = m_tvalid[j];
                wire m_tready_in = m_axis_tready[j];
                wire m_tlast_in = m_tlast[j];
                wire [DATA_WIDTH-1:0] m_tdata_in = m_tdata[j*DATA_WIDTH +: DATA_WIDTH];
                wire [KEEP_WIDTH-1:0] m_tkeep_in = m_tkeep[j*KEEP_WIDTH +: KEEP_WIDTH];
                wire [M_ID_WIDTH-1:0] m_tid_in = m_tid[j*M_ID_WIDTH +: M_ID_WIDTH];
                wire [M_DEST_WIDTH-1:0] m_tdest_in = m_tdest[j*M_DEST_WIDTH +: M_DEST_WIDTH];
                wire [USER_WIDTH-1:0] m_tuser_in = m_tuser[j*USER_WIDTH +: USER_WIDTH];

                always @(posedge clk or posedge rst) begin
                    if (rst) begin
                        m_tdata_reg <= {DATA_WIDTH{1'b0}};
                        m_tkeep_reg <= {KEEP_WIDTH{1'b0}};
                        m_tvalid_reg <= 1'b0;
                        m_tlast_reg <= 1'b0;
                        m_tid_reg <= {M_ID_WIDTH{1'b0}};
                        m_tdest_reg <= {M_DEST_WIDTH{1'b0}};
                        m_tuser_reg <= {USER_WIDTH{1'b0}};
                        m_tready_reg <= 1'b0;
                    end else begin
                        if (m_tvalid_in && m_tready_in) begin
                            m_tdata_reg <= m_tdata_in;
                            m_tkeep_reg <= m_tkeep_in;
                            m_tvalid_reg <= 1'b1;
                            m_tlast_reg <= m_tlast_in;
                            m_tid_reg <= m_tid_in;
                            m_tdest_reg <= m_tdest_in;
                            m_tuser_reg <= m_tuser_in;
                        end else if (m_tvalid_in) begin
                            m_tdata_reg <= m_tdata_in;
                            m_tkeep_reg <= m_tkeep_in;
                            m_tvalid_reg <= 1'b1;
                            m_tlast_reg <= m_tlast_in;
                            m_tid_reg <= m_tid_in;
                            m_tdest_reg <= m_tdest_in;
                            m_tuser_reg <= m_tuser_in;
                        end else if (m_tready_in) begin
                            m_tvalid_reg <= 1'b0;
                        end
                        m_tready_reg <= m_tready_in;
                    end
                end

                assign m_tdata[j*DATA_WIDTH +: DATA_WIDTH] = m_tdata_reg;
                assign m_tkeep[j*KEEP_WIDTH +: KEEP_WIDTH] = m_tkeep_reg;
                assign m_tvalid[j] = m_tvalid_reg;
                assign m_tlast[j] = m_tlast_reg;
                assign m_tid[j*M_ID_WIDTH +: M_ID_WIDTH] = m_tid_reg;
                assign m_tdest[j*M_DEST_WIDTH +: M_DEST_WIDTH] = m_tdest_reg;
                assign m_tuser[j*USER_WIDTH +: USER_WIDTH] = m_tuser_reg;
                assign m_axis_tready[j] = m_tready_reg;
            end
        end else begin
            assign m_tdata = m_axis_tdata;
            assign m_tkeep = m_axis_tkeep;
            assign m_tvalid = m_axis_tvalid;
            assign m_tlast = m_axis_tlast;
            assign m_tid = m_axis_tid;
            assign m_tdest = m_axis_tdest;
            assign m_tuser = m_axis_tuser;
            assign m_axis_tready = m_tready;
        end
    endgenerate

    // Routing logic
    // For each output port j, determine which input port i is selected
    wire [S_COUNT-1:0] m_req [0:M_COUNT-1];
    wire [S_COUNT-1:0] m_grant [0:M_COUNT-1];
    wire [S_COUNT-1:0] m_sel [0:M_COUNT-1];

    genvar j;
    genvar i;
    for (j = 0; j < M_COUNT; j = j + 1) begin : gen_m
        // Request: input i wants to go to output j if s_tvalid[i] and s_tdest[i] == j and M_CONNECT[j][i]
        wire [S_COUNT-1:0] req;
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_req
            assign req[i] = s_tvalid[i] && (s_tdest[i*S_DEST_WIDTH +: S_DEST_WIDTH] == j[S_DEST_WIDTH-1:0]) && M_CONNECT[j][i];
        end
        assign m_req[j] = req;

        // Arbitration
        if (ARB_TYPE_ROUND_ROBIN) begin
            // Round-robin arbitration
            reg [S_COUNT-1:0] rr_ptr;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    rr_ptr <= {S_COUNT{1'b0}};
                end else begin
                    if (m_req[j] != 0) begin
                        // Find the next request after rr_ptr
                        reg [S_COUNT-1:0] grant;
                        integer k;
                        for (k = 0; k < S_COUNT; k = k + 1) begin
                            grant[k] = 1'b0;
                        end
                        // Rotate request by rr_ptr
                        wire [S_COUNT-1:0] rotated_req = (m_req[j] >> rr_ptr) | (m_req[j] << (S_COUNT - rr_ptr));
                        // Find first set bit
                        for (k = 0; k < S_COUNT; k = k + 1) begin
                            if (rotated_req[k]) begin
                                grant[(k + rr_ptr) % S_COUNT] = 1'b1;
                            end
                        end
                        // Update rr_ptr to the granted position + 1
                        rr_ptr <= (grant != 0) ? ((grant + 1) % S_COUNT) : rr_ptr;
                    end
                end
            end

            // Generate grant based on rr_ptr
            wire [S_COUNT-1:0] grant;
            integer k;
            for (k = 0; k < S_COUNT; k = k + 1) begin
                grant[k] = 1'b0;
            end
            // Rotate request by rr_ptr
            wire [S_COUNT-1:0] rotated_req = (m_req[j] >> rr_ptr) | (m_req[j] << (S_COUNT - rr_ptr));
            // Find first set bit
            for (k = 0; k < S_COUNT; k = k + 1) begin
                if (rotated_req[k]) begin
                    grant[(k + rr_ptr) % S_COUNT] = 1'b1;
                end
            end
            assign m_grant[j] = grant;
        end else begin
            // Fixed priority arbitration
            wire [S_COUNT-1:0] grant;
            integer k;
            for (k = 0; k < S_COUNT; k = k + 1) begin
                grant[k] = 1'b0;
            end
            if (ARB_LSB_HIGH_PRIORITY) begin
                // LSB has highest priority
                for (k = 0; k < S_COUNT; k = k + 1) begin
                    grant[k] = m_req[j][k] && !(m_req[j] & ((1 << k) - 1)) != 0;
                end
            end else begin
                // MSB has highest priority
                for (k = 0; k < S_COUNT; k = k + 1) begin
                    grant[k] = m_req[j][k] && !(m_req[j] & ~((1 << (k+1)) - 1)) != 0;
                end
            end
            assign m_grant[j] = grant;
        end

        // Select the granted input
        wire [S_COUNT-1:0] sel;
        for (i = 0; i < S_COUNT; i = i + 1) begin
            sel[i] = m_grant[j][i];
        end
        assign m_sel[j] = sel;
    end

    // Generate s_tready: input i is ready if it is granted by its destination
    genvar i2;
    for (i2 = 0; i2 < S_COUNT; i2 = i2 + 1) begin : gen_s_ready
        wire [M_COUNT-1:0] dest_ready;
        genvar j2;
        for (j2 = 0; j2 < M_COUNT; j2 = j2 + 1) begin : gen_dest_ready
            assign dest_ready[j2] = m_sel[j2][i2] && m_tready[j2];
        end
        assign s_tready[i2] = |dest_ready;
    end

    // Generate m_tvalid: output j is valid if any input is granted to it
    genvar j3;
    for (j3 = 0; j3 < M_COUNT; j3 = j3 + 1) begin : gen_m_valid
        assign m_tvalid[j3] = |m_sel[j3];
    end

    // Generate m_tdata, m_tkeep, m_tlast, m_tid, m_tdest, m_tuser
    genvar j4;
    for (j4 = 0; j4 < M_COUNT; j4 = j4 + 1) begin : gen_m_data
        wire [DATA_WIDTH-1:0] m_tdata_sel;
        wire [KEEP_WIDTH-1:0] m_tkeep_sel;
        wire m_tlast_sel;
        wire [M_ID_WIDTH-1:0] m_tid_sel;
        wire [M_DEST_WIDTH-1:0] m_tdest_sel;
        wire [USER_WIDTH-1:0] m_tuser_sel;

        genvar i3;
        for (i3 = 0; i3 < S_COUNT; i3 = i3 + 1) begin : gen_m_data_sel
            wire sel_i3 = m_sel[j4][i3];
            wire [DATA_WIDTH-1:0] data_i3 = s_tdata[i3*DATA_WIDTH +: DATA_WIDTH];
            wire [KEEP_WIDTH-1:0] keep_i3 = s_tkeep[i3*KEEP_WIDTH +: KEEP_WIDTH];
            wire last_i3 = s_tlast[i3];
            wire [S_ID_WIDTH-1:0] tid_i3 = s_tid[i3*S_ID_WIDTH +: S_ID_WIDTH];
            wire [S_DEST_WIDTH-1:0] tdest_i3 = s_tdest[i3*S_DEST_WIDTH +: S_DEST_WIDTH];
            wire [USER_WIDTH-1:0] tuser_i3 = s_tuser[i3*USER_WIDTH +: USER_WIDTH];

            // Update TID if enabled
            wire [M_ID_WIDTH-1:0] tid_out;
            if (UPDATE_TID) begin
                assign tid_out = {tid_i3, i3[$clog2(S_COUNT)-1:0]};
            end else begin
                assign tid_out = {tid_i3, {$clog2(S_COUNT){1'b0}}};
            end

            assign m_tdata_sel = sel_i3 ? data_i3 : m_tdata_sel;
            assign m_tkeep_sel = sel_i3 ? keep_i3 : m_tkeep_sel;
            assign m_tlast_sel = sel_i3 ? last_i3 : m_tlast_sel;
            assign m_tid_sel = sel_i3 ? tid_out : m_tid_sel;
            assign m_tdest_sel = sel_i3 ? tdest_i3[M_DEST_WIDTH-1:0] : m_tdest_sel;
            assign m_tuser_sel = sel_i3 ? tuser_i3 : m_tuser_sel;
        end

        assign m_tdata[j4*DATA_WIDTH +: DATA_WIDTH] = m_tdata_sel;
        assign m_tkeep[j4*KEEP_WIDTH +: KEEP_WIDTH] = m_tkeep_sel;
        assign m_tlast[j4] = m_tlast_sel;
        assign m_tid[j4*M_ID_WIDTH +: M_ID_WIDTH] = m_tid_sel;
        assign m_tdest[j4*M_DEST_WIDTH +: M_DEST_WIDTH] = m_tdest_sel;
        assign m_tuser[j4*USER_WIDTH +: USER_WIDTH] = m_tuser_sel;
    end

endmodule
