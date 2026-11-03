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

    /*
     * Internal signals
     */
    reg [S_COUNT-1:0]                       selected_input;
    reg [M_COUNT-1:0]                       selected_output;
    wire [S_COUNT-1:0]                      input_valid;
    wire [DATA_WIDTH-1:0]                   data_selector_output;
    wire [KEEP_WIDTH-1:0]                   keep_selector_output;
    wire                                    last_selector_output;
    wire [M_ID_WIDTH-1:0]                   id_selector_output;
    wire [M_DEST_WIDTH-1:0]                 dest_selector_output;
    wire [USER_WIDTH-1:0]                   user_selector_output;
    wire [M_COUNT-1:0]                      ready_selector_output;

    /*
     * Arbitration
     */
    wire [S_COUNT-1:0]                      arbiter_output;

    arbiter #(
        .S_COUNT(S_COUNT)
    ) arbiter_inst (
        .clk(clk),
        .rst(rst),
        .input_valid(input_valid),
        .selected_input(arbiter_output)
    );

    assign input_valid = s_axis_tvalid;

    /*
     * Selectors
     */
    selector #(
        .COUNT(S_COUNT),
        .WIDTH(DATA_WIDTH)
    ) data_selector (
        .clk(clk),
        .rst(rst),
        .select(arbiter_output),
        .inputs(s_axis_tdata),
        .output(data_selector_output)
    );

    selector #(
        .COUNT(S_COUNT),
        .WIDTH(KEEP_WIDTH)
    ) keep_selector (
        .clk(clk),
        .rst(rst),
        .select(arbiter_output),
        .inputs(s_axis_tkeep),
        .output(keep_selector_output)
    );

    selector #(
        .COUNT(S_COUNT),
        .WIDTH(1)
    ) last_selector (
        .clk(clk),
        .rst(rst),
        .select(arbiter_output),
        .inputs(s_axis_tlast),
        .output(last_selector_output)
    );

    selector #(
        .COUNT(S_COUNT),
        .WIDTH(M_ID_WIDTH)
    ) id_selector (
        .clk(clk),
        .rst(rst),
        .select(arbiter_output),
        .inputs(s_axis_tid),
        .output(id_selector_output)
    );

    selector #(
        .COUNT(S_COUNT),
        .WIDTH(M_DEST_WIDTH)
    ) dest_selector (
        .clk(clk),
        .rst(rst),
        .select(arbiter_output),
        .inputs(s_axis_tdest),
        .output(dest_selector_output)
    );

    selector #(
        .COUNT(S_COUNT),
        .WIDTH(USER_WIDTH)
    ) user_selector (
        .clk(clk),
        .rst(rst),
        .select(arbiter_output),
        .inputs(s_axis_tuser),
        .output(user_selector_output)
    );

    /*
     * Ready Selector
     */
    ready_selector #(
        .M_COUNT(M_COUNT),
        .S_COUNT(S_COUNT)
    ) ready_selector_inst (
        .clk(clk),
        .rst(rst),
        .m_axis_tready(m_axis_tready),
        .selected_output(arbiter_output),
        .output(ready_selector_output)
    );

    /*
     * Output Assignment
     */
    assign m_axis_tdata = {M_COUNT{DATA_WIDTH{1'b0}}};
    assign m_axis_tkeep = {M_COUNT{KEEP_WIDTH{1'b0}}};
    assign m_axis_tlast = {M_COUNT{1'b0}};
    assign m_axis_tid = {M_COUNT{M_ID_WIDTH{1'b0}}};
    assign m_axis_tdest = {M_COUNT{M_DEST_WIDTH{1'b0}}};
    assign m_axis_tuser = {M_COUNT{USER_WIDTH{1'b0}}};
    assign m_axis_tvalid = ready_selector_output;

    genvar i;
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_m_axis
            assign m_axis_tdata[i*DATA_WIDTH +: DATA_WIDTH] = data_selector_output;
            assign m_axis_tkeep[i*KEEP_WIDTH +: KEEP_WIDTH] = keep_selector_output;
            assign m_axis_tlast[i] = last_selector_output;
            assign m_axis_tid[i*M_ID_WIDTH +: M_ID_WIDTH] = id_selector_output;
            assign m_axis_tdest[i*M_DEST_WIDTH +: M_DEST_WIDTH] = dest_selector_output;
            assign m_axis_tuser[i*USER_WIDTH +: USER_WIDTH] = user_selector_output;
        end
    endgenerate

    /*
     * Ready Signal Assignment
     */
    assign s_axis_tready = ready_selector_output;

endmodule

module arbiter #
(
    parameter S_COUNT = 4
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [S_COUNT-1:0]   input_valid,
    output reg [S_COUNT-1:0]    selected_input
);

    reg [$clog2(S_COUNT)-1:0]   round_robin_counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round_robin_counter <= 0;
            selected_input <= 0;
        end else begin
            if (|input_valid) begin
                integer i;
                for (i = 0; i < S_COUNT; i = i + 1) begin
                    if (input_valid[(round_robin_counter + i) % S_COUNT]) begin
                        selected_input <= 1 << ((round_robin_counter + i) % S_COUNT);
                        round_robin_counter <= (round_robin_counter + i + 1) % S_COUNT;
                        break;
                    end
                end
            end else begin
                selected_input <= 0;
            end
        end
    end

endmodule

module selector #
(
    parameter COUNT = 4,
    parameter WIDTH = 8
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [COUNT-1:0]     select,
    input  wire [COUNT*WIDTH-1:0] inputs,
    output reg [WIDTH-1:0]      output
);

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output <= 0;
        end else begin
            for (i = 0; i < COUNT; i = i + 1) begin
                if (select[i]) begin
                    output <= inputs[i*WIDTH +: WIDTH];
                    break;
                end
            end
        end
    end

endmodule

module ready_selector #
(
    parameter M_COUNT = 4,
    parameter S_COUNT = 4
)
(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [M_COUNT-1:0]   m_axis_tready,
    input  wire [S_COUNT-1:0]   selected_output,
    output reg [S_COUNT-1:0]    output
);

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output <= 0;
        end else begin
            output <= 0;
            for (i = 0; i < M_COUNT; i = i + 1) begin
                if (selected_output[i]) begin
                    output <= m_axis_tready[i];
                    break;
                end
            end
        end
    end

endmodule
