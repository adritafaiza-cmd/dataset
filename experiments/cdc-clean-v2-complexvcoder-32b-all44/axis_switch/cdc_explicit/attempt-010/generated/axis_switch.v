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
    wire [S_COUNT-1:0] input_requests;
    wire [S_COUNT-1:0] grant;
    wire valid_grant;
    wire [S_COUNT-1:0] input_ready;
    wire [M_COUNT*DATA_WIDTH-1:0] output_data;
    wire [M_COUNT*KEEP_WIDTH-1:0] output_keep;
    wire [M_COUNT-1:0] output_valid;
    wire [M_COUNT-1:0] output_last;
    wire [M_COUNT*M_ID_WIDTH-1:0] output_tid;
    wire [M_COUNT*M_DEST_WIDTH-1:0] output_dest;
    wire [M_COUNT*USER_WIDTH-1:0] output_user;

    // Generate input requests based on tvalid and tdest
    genvar i;
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_input_requests
            assign input_requests[i] = s_axis_tvalid[i];
        end
    endgenerate

    // Round-robin arbiter
    round_robin_arbiter_4x1 round_robin_arbiter (
        .clk(clk),
        .rst(rst),
        .requests(input_requests),
        .grant(grant),
        .valid(valid_grant)
    );

    // Generate input ready signals
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_input_ready
            assign input_ready[i] = grant[i] & m_axis_tready[grant[i]];
        end
    endgenerate

    // Generate output signals
    generate
        for (i = 0; i < M_COUNT; i = i + 1) begin : gen_outputs
            reg [DATA_WIDTH-1:0] data_reg;
            reg [KEEP_WIDTH-1:0] keep_reg;
            reg valid_reg;
            reg last_reg;
            reg [M_ID_WIDTH-1:0] tid_reg;
            reg [M_DEST_WIDTH-1:0] dest_reg;
            reg [USER_WIDTH-1:0] user_reg;

            integer j;
            always @(posedge clk or posedge rst) begin
                if (rst) begin
                    data_reg <= 0;
                    keep_reg <= 0;
                    valid_reg <= 0;
                    last_reg <= 0;
                    tid_reg <= 0;
                    dest_reg <= 0;
                    user_reg <= 0;
                end else begin
                    valid_reg <= 0;
                    for (j = 0; j < S_COUNT; j = j + 1) begin
                        if (grant[j] == i && input_ready[j]) begin
                            data_reg <= s_axis_tdata[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH];
                            keep_reg <= s_axis_tkeep[(j+1)*KEEP_WIDTH-1:j*KEEP_WIDTH];
                            valid_reg <= s_axis_tvalid[j];
                            last_reg <= s_axis_tlast[j];
                            tid_reg <= s_axis_tid[(j+1)*S_ID_WIDTH-1:j*S_ID_WIDTH];
                            dest_reg <= s_axis_tdest[(j+1)*S_DEST_WIDTH-1:j*S_DEST_WIDTH];
                            user_reg <= s_axis_tuser[(j+1)*USER_WIDTH-1:j*USER_WIDTH];
                        end
                    end
                end
            end

            assign m_axis_tdata[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH] = data_reg;
            assign m_axis_tkeep[(i+1)*KEEP_WIDTH-1:i*KEEP_WIDTH] = keep_reg;
            assign m_axis_tvalid[i] = valid_reg;
            assign m_axis_tlast[i] = last_reg;
            assign m_axis_tid[(i+1)*M_ID_WIDTH-1:i*M_ID_WIDTH] = tid_reg;
            assign m_axis_tdest[(i+1)*M_DEST_WIDTH-1:i*M_DEST_WIDTH] = dest_reg;
            assign m_axis_tuser[(i+1)*USER_WIDTH-1:i*USER_WIDTH] = user_reg;
        end
    endgenerate

    // Assign s_axis_tready
    generate
        for (i = 0; i < S_COUNT; i = i + 1) begin : gen_s_axis_tready
            assign s_axis_tready[i] = input_ready[i];
        end
    endgenerate

endmodule

// Round-robin arbiter module
module round_robin_arbiter_4x1 (
    input  wire clk,
    input  wire rst,
    input  wire [3:0] requests,
    output reg [3:0] grant,
    output reg valid
);

    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            grant <= 0;
            valid <= 0;
        end else begin
            if (requests != 0) begin
                case (state)
                    2'b00: begin
                        if (requests[0]) begin
                            grant <= 4'b0001;
                            valid <= 1;
                        end else if (requests[1]) begin
                            grant <= 4'b0010;
                            valid <= 1;
                        end else if (requests[2]) begin
                            grant <= 4'b0100;
                            valid <= 1;
                        end else if (requests[3]) begin
                            grant <= 4'b1000;
                            valid <= 1;
                        end
                    end
                    2'b01: begin
                        if (requests[1]) begin
                            grant <= 4'b0010;
                            valid <= 1;
                        end else if (requests[2]) begin
                            grant <= 4'b0100;
                            valid <= 1;
                        end else if (requests[3]) begin
                            grant <= 4'b1000;
                            valid <= 1;
                        end else if (requests[0]) begin
                            grant <= 4'b0001;
                            valid <= 1;
                        end
                    end
                    2'b10: begin
                        if (requests[2]) begin
                            grant <= 4'b0100;
                            valid <= 1;
                        end else if (requests[3]) begin
                            grant <= 4'b1000;
                            valid <= 1;
                        end else if (requests[0]) begin
                            grant <= 4'b0001;
                            valid <= 1;
                        end else if (requests[1]) begin
                            grant <= 4'b0010;
                            valid <= 1;
                        end
                    end
                    2'b11: begin
                        if (requests[3]) begin
                            grant <= 4'b1000;
                            valid <= 1;
                        end else if (requests[0]) begin
                            grant <= 4'b0001;
                            valid <= 1;
                        end else if (requests[1]) begin
                            grant <= 4'b0010;
                            valid <= 1;
                        end else if (requests[2]) begin
                            grant <= 4'b0100;
                            valid <= 1;
                        end
                    end
                endcase
            end else begin
                grant <= 0;
                valid <= 0;
            end
            if (valid) begin
                state <= state + 1;
            end
        end
    end

endmodule
