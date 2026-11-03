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
    /*
     * AXI input
     */
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
    /*
     * AXI output
     */
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
    /*
     * Pause
     */
    input  wire                     s_pause_req,
    output wire                     s_pause_ack,
    input  wire                     m_pause_req,
    output wire                     m_pause_ack,
    /*
     * Status
     */
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

    wire [M_DATA_WIDTH-1:0] fifo_wr_data;
    wire fifo_wr_en;
    wire fifo_full;
    wire [M_DATA_WIDTH-1:0] fifo_rd_data;
    wire fifo_rd_en;
    wire fifo_empty;
    wire [$clog2(DEPTH):0] fifo_depth;

    wire [S_DATA_WIDTH-1:0] data_width_adapter_output_data;
    wire [S_KEEP_WIDTH-1:0] data_width_adapter_output_keep;
    wire data_width_adapter_output_valid;
    wire data_width_adapter_output_last;
    wire [ID_WIDTH-1:0] data_width_adapter_output_id;
    wire [DEST_WIDTH-1:0] data_width_adapter_output_dest;
    wire [USER_WIDTH-1:0] data_width_adapter_output_user;

    wire [M_DATA_WIDTH-1:0] data_width_adapter_input_data;
    wire [S_KEEP_WIDTH-1:0] data_width_adapter_input_keep;
    wire data_width_adapter_input_valid;
    wire data_width_adapter_input_last;
    wire [ID_WIDTH-1:0] data_width_adapter_input_id;
    wire [DEST_WIDTH-1:0] data_width_adapter_input_dest;
    wire [USER_WIDTH-1:0] data_width_adapter_input_user;
    wire data_width_adapter_input_ready;

    wire s_pause_ack_int;
    wire m_pause_ack_int;

    assign s_pause_ack = s_pause_ack_int;
    assign m_pause_ack = m_pause_ack_int;

    assign s_axis_tready = data_width_adapter_input_ready;

    assign m_axis_tdata = data_width_adapter_output_data;
    assign m_axis_tkeep = data_width_adapter_output_keep;
    assign m_axis_tvalid = data_width_adapter_output_valid;
    assign m_axis_tlast = data_width_adapter_output_last;
    assign m_axis_tid = data_width_adapter_output_id;
    assign m_axis_tdest = data_width_adapter_output_dest;
    assign m_axis_tuser = data_width_adapter_output_user;

    assign fifo_wr_data = data_width_adapter_output_data;
    assign fifo_wr_en = data_width_adapter_output_valid;
    assign data_width_adapter_input_ready = ~fifo_full;

    assign data_width_adapter_output_data = fifo_rd_data;
    assign data_width_adapter_output_valid = ~fifo_empty;
    assign fifo_rd_en = data_width_adapter_output_valid & m_axis_tready;

    async_fifo #(
        .WIDTH(M_DATA_WIDTH),
        .DEPTH(DEPTH)
    ) s_to_m_async_fifo (
        .clk_wr(s_clk),
        .rst_wr(s_rst),
        .wr_data(fifo_wr_data),
        .wr_en(fifo_wr_en),
        .full(fifo_full),
        .clk_rd(m_clk),
        .rst_rd(m_rst),
        .rd_data(fifo_rd_data),
        .rd_en(fifo_rd_en),
        .empty(fifo_empty),
        .depth(fifo_depth)
    );

    width_adapter #(
        .S_DATA_WIDTH(S_DATA_WIDTH),
        .S_KEEP_WIDTH(S_KEEP_WIDTH),
        .M_DATA_WIDTH(M_DATA_WIDTH),
        .M_KEEP_WIDTH(M_KEEP_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .DEST_WIDTH(DEST_WIDTH),
        .USER_WIDTH(USER_WIDTH)
    ) data_width_adapter (
        .input_data(data_width_adapter_input_data),
        .input_keep(data_width_adapter_input_keep),
        .input_valid(data_width_adapter_input_valid),
        .input_last(data_width_adapter_input_last),
        .input_id(data_width_adapter_input_id),
        .input_dest(data_width_adapter_input_dest),
        .input_user(data_width_adapter_input_user),
        .input_ready(data_width_adapter_input_ready),
        .output_data(data_width_adapter_output_data),
        .output_keep(data_width_adapter_output_keep),
        .output_valid(data_width_adapter_output_valid),
        .output_last(data_width_adapter_output_last),
        .output_id(data_width_adapter_output_id),
        .output_dest(data_width_adapter_output_dest),
        .output_user(data_width_adapter_output_user),
        .output_ready(m_axis_tready)
    );

    assign data_width_adapter_input_data = s_axis_tdata;
    assign data_width_adapter_input_keep = s_axis_tkeep;
    assign data_width_adapter_input_valid = s_axis_tvalid;
    assign data_width_adapter_input_last = s_axis_tlast;
    assign data_width_adapter_input_id = s_axis_tid;
    assign data_width_adapter_input_dest = s_axis_tdest;
    assign data_width_adapter_input_user = s_axis_tuser;

    // Status outputs
    assign s_status_depth = fifo_depth;
    assign s_status_depth_commit = fifo_depth;
    assign s_status_overflow = fifo_full;
    assign s_status_bad_frame = 1'b0; // Placeholder for actual implementation
    assign s_status_good_frame = 1'b0; // Placeholder for actual implementation

    assign m_status_depth = fifo_depth;
    assign m_status_depth_commit = fifo_depth;
    assign m_status_overflow = fifo_full;
    assign m_status_bad_frame = 1'b0; // Placeholder for actual implementation
    assign m_status_good_frame = 1'b0; // Placeholder for actual implementation

    // Pause request handling
    assign s_pause_ack_int = s_pause_req;
    assign m_pause_ack_int = m_pause_req;

endmodule

module async_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 4096
)
(
    input wire clk_wr,
    input wire rst_wr,
    input wire [WIDTH-1:0] wr_data,
    input wire wr_en,
    output reg full,
    input wire clk_rd,
    input wire rst_rd,
    output reg [WIDTH-1:0] rd_data,
    input wire rd_en,
    output reg empty,
    output reg [$clog2(DEPTH):0] depth
);

    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_gray, rd_ptr_gray;
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk_wr or posedge rst_wr) begin
        if (rst_wr) begin
            wr_ptr <= 0;
            wr_ptr_gray <= 0;
            full <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1;
                wr_ptr_gray <= (wr_ptr + 1) ^ ((wr_ptr + 1) >> 1);
            end
            if (wr_ptr_gray != (rd_ptr_gray ^ (rd_ptr_gray >> 1))) begin
                full <= 0;
            end else if (wr_ptr_gray == ((rd_ptr_gray + 1) ^ ((rd_ptr_gray + 1) >> 1))) begin
                full <= 1;
            end
        end
    end

    always @(posedge clk_rd or posedge rst_rd) begin
        if (rst_rd) begin
            rd_ptr <= 0;
            rd_ptr_gray <= 0;
            empty <= 1;
        end else begin
            if (rd_en && !empty) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                rd_ptr_gray <= (rd_ptr + 1) ^ ((rd_ptr + 1) >> 1);
            end
            if (rd_ptr_gray != (wr_ptr_gray ^ (wr_ptr_gray >> 1))) begin
                empty <= 0;
            end else if (rd_ptr_gray == (wr_ptr_gray ^ (wr_ptr_gray >> 1))) begin
                empty <= 1;
            end
        end
    end

    always @(wr_ptr or rd_ptr) begin
        depth = wr_ptr - rd_ptr;
    end

endmodule

module width_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_WIDTH = 1,
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_WIDTH = 1,
    parameter ID_WIDTH = 8,
    parameter DEST_WIDTH = 8,
    parameter USER_WIDTH = 1
)
(
    input wire [S_DATA_WIDTH-1:0] input_data,
    input wire [S_KEEP_WIDTH-1:0] input_keep,
    input wire input_valid,
    input wire input_last,
    input wire [ID_WIDTH-1:0] input_id,
    input wire [DEST_WIDTH-1:0] input_dest,
    input wire [USER_WIDTH-1:0] input_user,
    output wire input_ready,
    output wire [M_DATA_WIDTH-1:0] output_data,
    output wire [M_KEEP_WIDTH-1:0] output_keep,
    output wire output_valid,
    output wire output_last,
    output wire [ID_WIDTH-1:0] output_id,
    output wire [DEST_WIDTH-1:0] output_dest,
    output wire [USER_WIDTH-1:0] output_user,
    input wire output_ready
);

    reg [S_DATA_WIDTH-1:0] data_reg;
    reg [S_KEEP_WIDTH-1:0] keep_reg;
    reg last_reg;
    reg [ID_WIDTH-1:0] id_reg;
    reg [DEST_WIDTH-1:0] dest_reg;
    reg [USER_WIDTH-1:0] user_reg;
    reg valid_reg;

    always @(posedge output_ready or posedge input_valid) begin
        if (input_valid) begin
            data_reg <= input_data;
            keep_reg <= input_keep;
            last_reg <= input_last;
            id_reg <= input_id;
            dest_reg <= input_dest;
            user_reg <= input_user;
            valid_reg <= 1;
        end else if (output_ready) begin
            valid_reg <= 0;
        end
    end

    assign output_data = data_reg;
    assign output_keep = keep_reg;
    assign output_valid = valid_reg;
    assign output_last = last_reg;
    assign output_id = id_reg;
    assign output_dest = dest_reg;
    assign output_user = user_reg;

    assign input_ready = !valid_reg;

endmodule
