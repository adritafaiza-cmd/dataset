```verilog
`timescale 1ns/1ps

module axis_async_fifo #
(
    parameter DEPTH = 4096,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter LAST_ENABLE = 1,
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
    input  wire                   s_clk,
    input  wire                   s_rst,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    input  wire                   m_clk,
    input  wire                   m_rst,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    output wire [$clog2(DEPTH):0] s_status_depth,
    output wire [$clog2(DEPTH):0] s_status_depth_commit,
    output wire                   s_status_overflow,
    output wire                   s_status_bad_frame,
    output wire                   s_status_good_frame,
    output wire [$clog2(DEPTH):0] m_status_depth,
    output wire [$clog2(DEPTH):0] m_status_depth_commit,
    output wire                   m_status_overflow,
    output wire                   m_status_bad_frame,
    output wire                   m_status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam KEEP_WIDTH_LOG2 = $clog2(KEEP_WIDTH);
    localparam ID_WIDTH_LOG2 = $clog2(ID_WIDTH);
    localparam DEST_WIDTH_LOG2 = $clog2(DEST_WIDTH);
    localparam USER_WIDTH_LOG2 = $clog2(USER_WIDTH);

    // Internal pointers and counters
    reg [LOG2_DEPTH:0] s_write_ptr;
    reg [LOG2_DEPTH:0] s_read_ptr;
    reg [LOG2_DEPTH:0] m_write_ptr;
    reg [LOG2_DEPTH:0] m_read_ptr;
    reg [LOG2_DEPTH:0] s_write_ptr_commit;
    reg [LOG2_DEPTH:0] s_read_ptr_commit;
    reg [LOG2_DEPTH:0] m_write_ptr_commit;
    reg [LOG2_DEPTH:0] m_read_ptr_commit;

    reg [LOG2_DEPTH:0] s_depth;
    reg [LOG2_DEPTH:0] m_depth;

    reg s_axis_tready_reg;
    reg m_axis_tvalid_reg;

    // Frame state
    reg s_frame_valid;
    reg m_frame_valid;
    reg s_frame_commit;
    reg m_frame_commit;
    reg s_frame_bad;
    reg m_frame_bad;
    reg s_frame_oversize;
    reg m_frame_oversize;
    reg s_frame_pause;
    reg m_frame_pause;

    // Bad frame detection
    reg s_bad_frame;
    reg m_bad_frame;

    // Oversize detection
    reg s_oversize;
    reg m_oversize;

    // Pause state
    reg s_pause_state;
    reg m_pause_state;

    // Frame FIFO logic
    reg s_frame_fifo_valid;
    reg m_frame_fifo_valid;
    reg s_frame_fifo_commit;
    reg m_frame_fifo_commit;

    // RAM Pipeline
    reg [DATA_WIDTH-1:0] s_ram_pipeline_data;
    reg [KEEP_WIDTH-1:0] s_ram_pipeline_keep;
    reg s_ram_pipeline_valid;
    reg s_ram_pipeline_last;
    reg s_ram_pipeline_tid;
    reg s_ram_pipeline_tdest;
    reg s_ram_pipeline_tuser;
    reg s_ram_pipeline_tlast;

    reg [DATA_WIDTH-1:0] m_ram_pipeline_data;
    reg [KEEP_WIDTH-1:0] m_ram_pipeline_keep;
    reg m_ram_pipeline_valid;
    reg m_ram_pipeline_last;
    reg m_ram_pipeline_tid;
    reg m_ram_pipeline_tdest;
    reg m_ram_pipeline_tuser;
    reg m_ram_pipeline_tlast;

    // Status signals
    wire s_depth_empty = (s_write_ptr == s_read_ptr);
    wire s_depth_full = (s_write_ptr == (s_read_ptr + LOG2_DEPTH));
    wire m_depth_empty = (m_write_ptr == m_read_ptr);
    wire m_depth_full = (m_write_ptr == (m_read_ptr + LOG2_DEPTH));

    // Generate keep signals
    generate
        genvar i;
        for (i = 0; i < KEEP_WIDTH; i = i + 1) begin : gen_keep
            assign s_axis_tkeep[i] = (s_axis_tkeep[i] == 1'b1);
            assign m_axis_tkeep[i] = (m_axis_tkeep[i] == 1'b1);
        end
    endgenerate

    // Synchronous logic for s-side
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_write_ptr <= 0;
            s_read_ptr <= 0;
            s_write_ptr_commit <= 0;
            s_read_ptr_commit <= 0;
            s_depth <= 0;
            s_axis_tready_reg <= 0;
            s_frame_valid <= 0;
            s_frame_commit <= 0;
            s_frame_bad <= 0;
            s_frame_oversize <= 0;
            s_frame_pause <= 0;
            s_bad_frame <= 0;
            s_oversize <= 0;
            s_pause_state <= 0;
            s_frame_fifo_valid <= 0;
            s_frame_fifo_commit <= 0;
            s_ram_pipeline_valid <= 0;
            s_ram_pipeline_last <= 0;
            s_ram_pipeline_tid <= 0;
            s_ram_pipeline_tdest <= 0;
            s_ram_pipeline_tuser <= 0;
            s_ram_pipeline_tlast <= 0;
        end else begin
            s_write_ptr <= s_write_ptr;
            s_read_ptr <= s_read_ptr;
            s_write_ptr_commit <= s_write_ptr_commit;
            s_read_ptr_commit <= s_read_ptr_commit;
            s_depth <= s_depth;
            s_axis_tready_reg <= s_axis_tready_reg;
            s_frame_valid <= s_frame_valid;
            s_frame_commit <= s_frame_commit;
            s_frame_bad <= s_frame_bad;
            s_frame_oversize <= s_frame_oversize;
            s_frame_pause <= s_frame_pause;
            s_bad_frame <= s_bad_frame;
            s_oversize <= s_oversize;
            s_pause_state <= s_pause_state;
            s_frame_fifo_valid <= s_frame_fifo_valid;
            s_frame_fifo_commit <= s_frame_fifo_commit;
            s_ram_pipeline_valid <= s_ram_pipeline_valid;
            s_ram_pipeline_last <= s_ram_pipeline_last;
            s_ram_pipeline_tid <= s_ram_pipeline_tid;
            s_ram_pipeline_tdest <= s_ram_pipeline_tdest;
            s_ram_pipeline_tuser <= s_ram_pipeline_tuser;
            s_ram_pipeline_tlast <= s_ram_pipeline_tlast;
        end
    end

    // Synchronous logic for m-side
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_write_ptr <= 0;
            m_read_ptr <= 0;
            m_write_ptr_commit <= 0;
            m_read_ptr_commit <= 0;
            m_depth <= 0;
            m_axis_tvalid_reg <= 0;
            m_frame_valid <= 0;
            m_frame_commit <= 0;
            m_frame_bad <= 0;
            m_frame_oversize <= 0;
            m_frame_pause <= 0;
            m_bad_frame <= 0;
            m_oversize <= 0;
            m_pause_state <= 0;
            m_frame_fifo_valid <= 0;
            m_frame_fifo_commit <= 0;
            m_ram_pipeline_valid <= 0;
            m_ram_pipeline_last <= 0;
            m_ram_pipeline_tid <= 0;
            m_ram_pipeline_tdest <= 0;
            m_ram_pipeline_tuser <= 0;
            m_ram_pipeline_tlast <= 0;
        end else begin
            m_write_ptr <= m_write_ptr;
            m_read_ptr <= m_read_ptr;
            m_write_ptr_commit <= m_write_ptr_commit;
            m_read_ptr_commit <= m_read_ptr_commit;
            m_depth <= m_depth;
            m_axis_tvalid_reg <= m_axis_tvalid_reg;
            m_frame_valid <= m_frame_valid;
            m_frame_commit <= m_frame_commit;
            m_frame_bad <= m_frame_bad;
            m_frame_oversize <= m_frame_oversize;
            m_frame_pause <= m_frame_pause;
            m_bad_frame <= m_bad_frame;
            m_oversize <= m_oversize;
            m_pause_state <= m_pause_state;
            m_frame_fifo_valid <= m_frame_fifo_valid;
            m_frame_fifo_commit <= m_frame_fifo_commit;
            m_ram_pipeline_valid <= m_ram_pipeline_valid;
            m_ram_pipeline_last <= m_ram_pipeline_last;
            m_ram_pipeline_tid <= m_ram_pipeline_tid;
            m_ram_pipeline_tdest <= m_ram_pipeline_tdest;
            m_ram_pipeline_tuser <= m_ram_pipeline_tuser;
            m_ram_pipeline_tlast <= m_ram_pipeline_tlast;
        end
    end

    // Synchronous logic for s-side pipeline
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ram_pipeline_data <= 0;
            s_ram_pipeline_keep <= 0;
            s_ram_pipeline_valid <= 0;
            s_ram_pipeline_last <= 0;
            s_ram_pipeline_tid <= 0;
            s_ram_pipeline_tdest <= 0;
            s_ram_pipeline_tuser <= 0;
            s_ram_pipeline_tlast <= 0;
        end else begin
            s_ram_pipeline_data <= s_ram_pipeline_data;
            s_ram_pipeline_keep <= s_ram_pipeline_keep;
            s_ram_pipeline_valid <= s_ram_pipeline_valid;
            s_ram_pipeline_last <= s_ram_pipeline_last;
            s_ram_pipeline_tid <= s_ram_pipeline_tid;
            s_ram_pipeline_tdest <= s_ram_pipeline_tdest;
            s_ram_pipeline_tuser <= s_ram_pipeline_tuser;
            s_ram_pipeline_tlast <= s_ram_pipeline_tlast;
        end
    end

    // Synchronous logic for m-side pipeline
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ram_pipeline_data <= 0;
            m_ram_pipeline_keep <= 0;
            m_ram_pipeline_valid <= 0;
            m_ram_pipeline_last <= 0;
            m_ram_pipeline_tid <= 0;
            m_ram_pipeline_tdest <= 0;
            m_ram_pipeline_tuser <= 0;
            m_ram_pipeline_tlast <= 0;
        end else begin
            m_ram_pipeline_data <= m_ram_pipeline_data;
            m_ram_pipeline_keep <= m_ram_pipeline_keep;
            m_ram_pipeline_valid <= m_ram_pipeline_valid;
            m_ram_pipeline_last <= m_ram_pipeline_last;
            m_ram_pipeline_tid <= m_ram_pipeline_tid;
            m_ram_pipeline_tdest <= m_ram_pipeline_tdest;
            m_ram_pipeline_tuser <= m_ram_pipeline_tuser;
            m_ram_pipeline_tlast <= m_ram_pipeline_tlast;
        end
    end

    // Synchronous logic for s-side frame FIFO
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_fifo_valid <= 0;
            s_frame_fifo_commit <= 0;
        end else begin
            s_frame_fifo_valid <= s_frame_fifo_valid;
            s_frame_fifo_commit <= s_frame_fifo_commit;
        end
    end

    // Synchronous logic for m-side frame FIFO
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_fifo_valid <= 0;
            m_frame_fifo_commit <= 0;
        end else begin
            m_frame_fifo_valid <= m_frame_fifo_valid;
            m_frame_fifo_commit <= m_frame_fifo_commit;
        end
    end

    // Synchronous logic for s-side pause state
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_state <= 0;
        end else begin
            s_pause_state <= s_pause_state;
        end
    end

    // Synchronous logic for m-side pause state
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_state <= 0;
        end else begin
            m_pause_state <= m_pause_state;
        end
    end

    // Synchronous logic for s-side bad frame
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bad_frame <= 0;
        end else begin
            s_bad_frame <= s_bad_frame;
        end
    end

    // Synchronous logic for m-side bad frame
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bad_frame <= 0;
        end else begin
            m_bad_frame <= m_bad_frame;
        end
    end

    // Synchronous logic for s-side oversize
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_oversize <= 0;
        end else begin
            s_oversize <= s_oversize;
        end
    end

    // Synchronous logic for m-side oversize
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_oversize <= 0;
        end else begin
            m_oversize <= m_oversize;
        end
    end

    // Synchronous logic for s-side frame pause
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_pause <= 0;
        end else begin
            s_frame_pause <= s_frame_pause;
        end
    end

    // Synchronous logic for m-side frame pause
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_pause <= 0;
        end else begin
            m_frame_pause <= m_frame_pause;
        end
    end

    // Synchronous logic for s-side frame valid
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_valid <= 0;
        end else begin
            s_frame_valid <= s_frame_valid;
        end
    end

    // Synchronous logic for m-side frame valid
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_valid <= 0;
        end else begin
            m_frame_valid <= m_frame_valid;
        end
    end

    // Synchronous logic for s-side frame commit
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_commit <= 0;
        end else begin
            s_frame_commit <= s_frame_commit;
        end
    end

    // Synchronous logic for m-side frame commit
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_commit <= 0;
        end else begin
            m_frame_commit <= m_frame_commit;
        end
    end

    // Synchronous logic for s-side depth
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth <= 0;
        end else begin
            s_depth <= s_depth;
        end
    end

    // Synchronous logic for m-side depth
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth <= 0;
        end else begin
            m_depth <= m_depth;
        end
    end

    // Synchronous logic for s-side depth commit
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth_commit <= 0;
        end else begin
            s_depth_commit <= s_depth_commit;
        end
    end

    // Synchronous logic for m-side depth commit
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth_commit <= 0;
        end else begin
            m_depth_commit <= m_depth_commit;
        end
    end

    // Synchronous logic for s-side overflow
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow <= 0;
        end else begin
            s_status_overflow <= s_status_overflow;
        end
    end

    // Synchronous logic for m-side overflow
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_overflow <= 0;
        end else begin
            m_status_overflow <= m_status_overflow;
        end
    end

    // Synchronous logic for s-side bad frame
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_bad_frame <= 0;
        end else begin
            s_status_bad_frame <= s_status_bad_frame;
        end
    end

    // Synchronous logic for m-side bad frame
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_bad_frame <= 0;
        end else begin
            m_status_bad_frame <= m_status_bad_frame;
        end
    end

    // Synchronous logic for s-side good frame
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_good_frame <= 0;
        end else begin
            s_status_good_frame <= s_status_good_frame;
        end
    end

    // Synchronous logic for m-side good frame
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_good_frame <= 0;
        end else begin
            m_status_good_frame <= m_status_good_frame;
        end
    end

    // Synchronous logic for s-side pause ack
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 0;
        end else begin
            s_pause_ack <= s_pause_ack;
        end
    end

    // Synchronous logic for m-side pause ack
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 0;
        end else begin
            m_pause_ack <= m_pause_ack;
        end
    end

    // Synchronous logic for s-side pause req
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_req <= 0;
        end else begin
            s_pause_req <= s_pause_req;
        end
    end

    // Synchronous logic for m-side pause req
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_req <= 0;
        end else begin
            m_pause_req <= m_pause_req;
        end
    end

    // Synchronous logic for s-side pause state
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_state <= 0;
        end else begin
            s_pause_state <= s_pause_state;
        end
    end

    // Synchronous logic for m-side pause state
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_state <= 0;
        end else begin
            m_pause_state <= m_pause_state;
        end
    end

    // Synchronous logic for s-side frame pause
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_pause <= 0;
        end else begin
            s_frame_pause <= s_frame_pause;
        end
    end

    // Synchronous logic for m-side frame pause
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_pause <= 0;
        end else begin
            m_frame_pause <= m_frame_pause;
        end
    end

    // Synchronous logic for s-side frame valid
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_valid <= 0;
        end else begin
            s_frame_valid <= s_frame_valid;
        end
    end

    // Synchronous logic for m-side frame valid
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_valid <= 0;
        end else begin
            m_frame_valid <= m_frame_valid;
        end
    end

    // Synchronous logic for s-side frame commit
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_commit <= 0;
        end else begin
            s_frame_commit <= s_frame_commit;
        end
    end

    // Synchronous logic for m-side frame commit
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_commit <= 0;
        end else begin
            m_frame_commit <= m_frame_commit;
        end
    end

    // Synchronous logic for s-side depth
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth <= 0;
        end else begin
            s_depth <= s_depth;
        end
    end

    // Synchronous logic for m-side depth
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth <= 0;
        end else begin
            m_depth <= m_depth;
        end
    end

    // Synchronous logic for s-side depth commit
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth_commit <= 0;
        end else begin
            s_depth_commit <= s_depth_commit;
        end
    end

    // Synchronous logic for m-side depth commit
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth_commit <= 0;
        end else begin
            m_depth_commit <= m_depth_commit;
        end
    end

    // Synchronous logic for s-side overflow
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow <= 0;
        end else begin
            s_status_overflow <= s_status_overflow;
        end
    end

    // Synchronous logic for m-side overflow
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_overflow <= 0;
        end else begin
            m_status_overflow <= m_status_overflow;
        end
    end

    // Synchronous logic for s-side bad frame
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_bad_frame <= 0;
        end else begin
            s_status_bad_frame <= s_status_bad_frame;
        end
    end

    // Synchronous logic for m-side bad frame
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_bad_frame <= 0;
        end else begin
            m_status_bad_frame <= m_status_bad_frame;
        end
    end

    // Synchronous logic for s-side good frame
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_good_frame <= 0;
        end else begin
            s_status_good_frame <= s_status_good_frame;
        end
    end

    // Synchronous logic for m-side good frame
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_good_frame <= 0;
        end else begin
            m_status_good_frame <= m_status_good_frame;
        end
    end

    // Synchronous logic for s-side pause ack
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 0;
        end else begin
            s_pause_ack <= s_pause_ack;
        end
    end

    // Synchronous logic for m-side pause ack
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 0;
        end else begin
            m_pause_ack <= m_pause_ack;
        end
    end

    // Synchronous logic for s-side pause req
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_req <= 0;
        end else begin
            s_pause_req <= s_pause_req;
        end
    end

    // Synchronous logic for m-side pause req
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_req <= 0;
        end else begin
            m_pause_req <= m_pause_req;
        end
    end

    // Synchronous logic for s-side pause state
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_state <= 0;
        end else begin
            s_pause_state <= s_pause_state;
        end
    end

    // Synchronous logic for m-side pause state
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_state <= 0;
        end else begin
            m_pause_state <= m_pause_state;
        end
    end

    // Synchronous logic for s-side frame pause
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_pause <= 0;
        end else begin
            s_frame_pause <= s_frame_pause;
        end
    end

    // Synchronous logic for m-side frame pause
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_pause <= 0;
        end else begin
            m_frame_pause <= m_frame_pause;
        end
    end

    // Synchronous logic for s-side frame valid
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_valid <= 0;
        end else begin
            s_frame_valid <= s_frame_valid;
        end
    end

    // Synchronous logic for m-side frame valid
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_valid <= 0;
        end else begin
            m_frame_valid <= m_frame_valid;
        end
    end

    // Synchronous logic for s-side frame commit
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_commit <= 0;
        end else begin
            s_frame_commit <= s_frame_commit;
        end
    end

    // Synchronous logic for m-side frame commit
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_commit <= 0;
        end else begin
            m_frame_commit <= m_frame_commit;
        end
    end

    // Synchronous logic for s-side depth
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth <= 0;
        end else begin
            s_depth <= s_depth;
        end
    end

    // Synchronous logic for m-side depth
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth <= 0;
        end else begin
            m_depth <= m_depth;
        end
    end

    // Synchronous logic for s-side depth commit
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_depth_commit <= 0;
        end else begin
            s_depth_commit <= s_depth_commit;
        end
    end

    // Synchronous logic for m-side depth commit
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_depth_commit <= 0;
        end else begin
            m_depth_commit <= m_depth_commit;
        end
    end

    // Synchronous logic for s-side overflow
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_overflow <= 0;
        end else begin
            s_status_overflow <= s_status_overflow;
        end
    end

    // Synchronous logic for m-side overflow
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_overflow <= 0;
        end else begin
            m_status_overflow <= m_status_overflow;
        end
    end

    // Synchronous logic for s-side bad frame
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_bad_frame <= 0;
        end else begin
            s_status_bad_frame <= s_status_bad_frame;
        end
    end

    // Synchronous logic for m-side bad frame
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_bad_frame <= 0;
        end else begin
            m_status_bad_frame <= m_status_bad_frame;
        end
    end

    // Synchronous logic for s-side good frame
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_status_good_frame <= 0;
        end else begin
            s_status_good_frame <= s_status_good_frame;
        end
    end

    // Synchronous logic for m-side good frame
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_status_good_frame <= 0;
        end else begin
            m_status_good_frame <= m_status_good_frame;
        end
    end

    // Synchronous logic for s-side pause ack
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_ack <= 0;
        end else begin
            s_pause_ack <= s_pause_ack;
        end
    end

    // Synchronous logic for m-side pause ack
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_ack <= 0;
        end else begin
            m_pause_ack <= m_pause_ack;
        end
    end

    // Synchronous logic for s-side pause req
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_req <= 0;
        end else begin
            s_pause_req <= s_pause_req;
        end
    end

    // Synchronous logic for m-side pause req
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_req <= 0;
        end else begin
            m_pause_req <= m_pause_req;
        end
    end

    // Synchronous logic for s-side pause state
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_state <= 0;
        end else begin
            s_pause_state <= s_pause_state;
        end
    end

    // Synchronous logic for m-side pause state
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_state <= 0;
        end else begin
            m_pause_state <= m_pause_state;
        end
    end

    // Synchronous logic for s-side frame pause
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_pause <= 0;
        end else begin
            s_frame_pause <= s_frame_pause;
        end
    end

    // Synchronous logic for m-side frame pause
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_pause <= 0;
        end else begin
            m_frame_pause <= m_frame_pause;
        end
    end

    // Synchronous logic for s-side frame valid
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_valid <= 0;
        end else begin
            s_frame_valid <= s_frame_valid;
        end
    end

    // Synchronous logic for m-side frame valid
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_valid <= 0;
        end else begin
            m_frame_valid <= m_frame_valid;
        end
    end

    // Synchronous logic for s-side frame commit
    always @(posedge s_clk or posedge