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
    reg [S_COUNT-1:0]                       s_axis_tready_reg;
    reg [M_COUNT-1:0]                       m_axis_tvalid_reg;
    reg [$clog2(S_COUNT)-1:0]               selected_input;
    reg [$clog2(M_COUNT)-1:0]               selected_output;
    reg [S_COUNT-1:0]                       grant;
    reg [S_COUNT-1:0]                       req;
    reg [$clog2(S_COUNT)-1:0]               round_robin_ptr;

    // Request generation
    always @(*) begin
        req = s_axis_tvalid & ~s_axis_tready_reg;
    end

    // Round-robin arbiter
    generate
        if (ARB_TYPE_ROUND_ROBIN) begin : rr_arbiter
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    round_robin_ptr <= 0;
                    grant <= 0;
                end else begin
                    if (|req) begin
                        integer i;
                        integer start;
                        start = round_robin_ptr;
                        for (i = 0; i < S_COUNT; i = i + 1) begin
                            if (req[(start + i) % S_COUNT]) begin
                                grant <= 0;
                                grant[(start + i) % S_COUNT] <= 1;
                                round_robin_ptr <= (start + i + 1) % S_COUNT;
                                break;
                            end
                        end
                    end else begin
                        grant <= 0;
                    end
                end
            end
        end else begin : no_arbiter
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    grant <= 0;
                end else begin
                    grant <= req;
                end
            end
        end
    endgenerate

    // Selected input and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            selected_input <= 0;
            selected_output <= 0;
        end else begin
            integer i;
            for (i = 0; i < S_COUNT; i = i + 1) begin
                if (grant[i]) begin
                    selected_input <= i;
                    selected_output <= s_axis_tdest[i*S_DEST_WIDTH +: M_DEST_WIDTH];
                    break;
                end
            end
        end
    end

    // Data routing
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_axis_tready
            assign s_axis_tready[i] = s_axis_tready_reg[i];
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis_tvalid
            assign m_axis_tvalid[i] = m_axis_tvalid_reg[i];
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis_tdata
            assign m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] = (i == selected_output) ? s_axis_tdata[selected_input*DATA_WIDTH +: DATA_WIDTH] : 0;
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis_tkeep
            assign m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] = (i == selected_output) ? s_axis_tkeep[selected_input*KEEP_WIDTH +: KEEP_WIDTH] : 0;
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis_tlast
            assign m_axis_tlast[i] = (i == selected_output) ? s_axis_tlast[selected_input] : 0;
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis_tid
            assign m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] = (i == selected_output) ? s_axis_tid[selected_input*S_ID_WIDTH +: S_ID_WIDTH] : 0;
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis_tdest
            assign m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] = (i == selected_output) ? s_axis_tdest[selected_input*S_DEST_WIDTH +: M_DEST_WIDTH] : 0;
        end
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis_tuser
            assign m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] = (i == selected_output) ? s_axis_tuser[selected_input*USER_WIDTH +: USER_WIDTH] : 0;
        end
    endgenerate

    // Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_reg <= 0;
            m_axis_tvalid_reg <= 0;
        end else begin
            integer i;
            for (i = 0; i < S_COUNT; i = i + 1) begin
                if (grant[i] && m_axis_tready[selected_output]) begin
                    s_axis_tready_reg[i] <= 1;
                end else begin
                    s_axis_tready_reg[i] <= 0;
                end
            end
            for (i = 0; i < M_COUNT; i = i + 1) begin
                if (grant[selected_input] && (i == selected_output)) begin
                    m_axis_tvalid_reg[i] <= 1;
                end else if (m_axis_tready[i]) begin
                    m_axis_tvalid_reg[i] <= 0;
                end
            end
        end
    end

endmodule
