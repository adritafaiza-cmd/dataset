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
    wire [S_COUNT-1:0]                    s_axis_tready_int;
    wire [M_COUNT-1:0]                    m_axis_tvalid_int;
    wire [M_COUNT*DATA_WIDTH-1:0]         m_axis_tdata_int;
    wire [M_COUNT*KEEP_WIDTH-1:0]         m_axis_tkeep_int;
    wire [M_COUNT-1:0]                    m_axis_tlast_int;
    wire [M_COUNT*M_ID_WIDTH-1:0]         m_axis_tid_int;
    wire [M_COUNT*M_DEST_WIDTH-1:0]       m_axis_tdest_int;
    wire [M_COUNT*USER_WIDTH-1:0]         m_axis_tuser_int;
    reg  [$clog2(S_COUNT)-1:0]            selected_input;
    wire [M_COUNT-1:0]                    valid_outputs;
    wire [S_COUNT-1:0]                    ready_inputs;
    wire [S_COUNT-1:0]                    grant;
    wire [S_COUNT-1:0]                    req;
    reg  [$clog2(S_COUNT)-1:0]            next_selected_input;
    reg  [$clog2(S_COUNT)-1:0]            round_robin_counter;

    // Generate valid_outputs and ready_inputs
    genvar i, j;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_valid_outputs
            assign valid_outputs[i] = |(s_axis_tvalid & {S_COUNT{m_axis_tready[i] & (s_axis_tdest[(i*S_DEST_WIDTH +: S_DEST_WIDTH) - M_DEST_WIDTH : (i*S_DEST_WIDTH +: S_DEST_WIDTH) - M_DEST_WIDTH] == i)}});
        end
        for (j = 0; j < S_COUNT; j = j + 1) begin : gen_ready_inputs
            assign ready_inputs[j] = m_axis_tready[s_axis_tdest[j*S_DEST_WIDTH +: S_DEST_WIDTH] - M_DEST_WIDTH];
        end
    endgenerate

    // Round-robin arbitration
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : gen_round_robin_arb
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    round_robin_counter <= 0;
                    selected_input <= 0;
                end else begin
                    next_selected_input <= selected_input;
                    if (|req) begin
                        for (i = 0; i < S_COUNT; i = i + 1) begin
                            if (req[(round_robin_counter + i) % S_COUNT]) begin
                                next_selected_input <= (round_robin_counter + i) % S_COUNT;
                                break;
                            end
                        end
                    end
                    if (grant[selected_input])
                        round_robin_counter <= round_robin_counter + 1;
                    selected_input <= next_selected_input;
                end
            end
        end else begin : gen_no_arb
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    selected_input <= 0;
                end else begin
                    for (i = 0; i < S_COUNT; i = i + 1) begin
                        if (req[i]) begin
                            selected_input <= i;
                            break;
                        end
                    end
                end
            end
        end
    endgenerate

    // Grant logic
    always @(*) begin
        grant = 0;
        if (req[selected_input] && m_axis_tready[s_axis_tdest[selected_input*S_DEST_WIDTH +: S_DEST_WIDTH] - M_DEST_WIDTH])
            grant[selected_input] = 1;
    end

    // Request logic
    assign req = s_axis_tvalid & ~s_axis_tready_int;

    // Assign tready based on grant
    genvar k;
    generate
        for (k = 0; k < S_COUNT; k = k + 1) begin : gen_tready
            assign s_axis_tready_int[k] = grant[k];
        end
    endgenerate

    // Assign tvalid based on grant
    genvar l;
    generate
        for (l = 0; l < M_COUNT; l = l + 1) begin : gen_tvalid
            assign m_axis_tvalid_int[l] = grant[selected_input] && (s_axis_tdest[selected_input*S_DEST_WIDTH +: S_DEST_WIDTH] - M_DEST_WIDTH == l);
        end
    endgenerate

    // Assign data signals
    genvar m;
    generate
        for (m = 0; m < M_COUNT; m = m + 1) begin : gen_data_assign
            assign m_axis_tdata_int[m*DATA_WIDTH +: DATA_WIDTH] = s_axis_tdata[selected_input*DATA_WIDTH +: DATA_WIDTH];
            assign m_axis_tkeep_int[m*KEEP_WIDTH +: KEEP_WIDTH] = s_axis_tkeep[selected_input*KEEP_WIDTH +: KEEP_WIDTH];
            assign m_axis_tlast_int[m] = s_axis_tlast[selected_input];
            assign m_axis_tid_int[m*M_ID_WIDTH +: M_ID_WIDTH] = (UPDATE_TID) ? {s_axis_tid[selected_input*S_ID_WIDTH +: S_ID_WIDTH], selected_input} : s_axis_tid[selected_input*S_ID_WIDTH +: S_ID_WIDTH];
            assign m_axis_tdest_int[m*M_DEST_WIDTH +: M_DEST_WIDTH] = s_axis_tdest[selected_input*S_DEST_WIDTH +: S_DEST_WIDTH] - M_DEST_WIDTH;
            assign m_axis_tuser_int[m*USER_WIDTH +: USER_WIDTH] = s_axis_tuser[selected_input*USER_WIDTH +: USER_WIDTH];
        end
    endgenerate

    // Register outputs if M_REG_TYPE is set
    generate
        if (M_REG_TYPE == 2) begin : gen_reg_outputs
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    m_axis_tdata <= 0;
                    m_axis_tkeep <= 0;
                    m_axis_tvalid <= 0;
                    m_axis_tlast <= 0;
                    m_axis_tid <= 0;
                    m_axis_tdest <= 0;
                    m_axis_tuser <= 0;
                end else begin
                    m_axis_tdata <= m_axis_tdata_int;
                    m_axis_tkeep <= m_axis_tkeep_int;
                    m_axis_tvalid <= m_axis_tvalid_int;
                    m_axis_tlast <= m_axis_tlast_int;
                    m_axis_tid <= m_axis_tid_int;
                    m_axis_tdest <= m_axis_tdest_int;
                    m_axis_tuser <= m_axis_tuser_int;
                end
            end
        end else begin : gen_no_reg_outputs
            assign m_axis_tdata = m_axis_tdata_int;
            assign m_axis_tkeep = m_axis_tkeep_int;
            assign m_axis_tvalid = m_axis_tvalid_int;
            assign m_axis_tlast = m_axis_tlast_int;
            assign m_axis_tid = m_axis_tid_int;
            assign m_axis_tdest = m_axis_tdest_int;
            assign m_axis_tuser = m_axis_tuser_int;
        end
    endgenerate

    // Assign tready outputs
    assign s_axis_tready = s_axis_tready_int;

endmodule
