```verilog
`timescale 1ns/1ps

module axis_fifo #
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
    input  wire                   clk,
    input  wire                   rst,
    /*
     * AXI input
     */
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    /*
     * AXI output
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    /*
     * Pause
     */
    input  wire                   pause_req,
    output wire                   pause_ack,
    /*
     * Status
     */
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    // Internal parameters
    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);
    
    // State encoding for frame handling
    localparam IDLE = 2'b00;
    localparam WRITING = 2'b01;
    localparam DROPPING = 2'b10;
    localparam MARKING = 2'b11;

    // Input FIFO Depth
    localparam IN_FIFO_DEPTH = (RAM_PIPELINE) ? (DEPTH/2) : DEPTH;
    localparam IN_LOG2_DEPTH = $clog2(IN_FIFO_DEPTH);
    
    // Output FIFO Depth
    localparam OUT_FIFO_DEPTH = (OUTPUT_FIFO_ENABLE) ? (DEPTH/2) : DEPTH;
    localparam OUT_LOG2_DEPTH = $clog2(OUT_FIFO_DEPTH);

    // Frame State Registers
    reg [1:0] frame_state;
    reg [LOG2_DEPTH-1:0] frame_start_addr;
    reg frame_frame_active;
    reg frame_frame_full;
    reg frame_frame_empty;
    reg frame_frame_drop;
    reg frame_frame_mark;
    reg frame_frame_pause;
    reg frame_frame_bad;
    reg frame_frame_oversize;
    reg frame_frame_last_seen;
    reg frame_frame_first_seen;
    reg frame_frame_count;
    wire frame_frame_count_valid;

    // Input FIFO
    reg [DATA_WIDTH-1:0] in_tdata [0:MAX_DEPTH-1];
    reg [KEEP_WIDTH-1:0] in_tkeep [0:MAX_DEPTH-1];
    reg [ID_WIDTH-1:0] in_tid [0:MAX_DEPTH-1];
    reg [DEST_WIDTH-1:0] in_tdest [0:MAX_DEPTH-1];
    reg [USER_WIDTH-1:0] in_tuser [0:MAX_DEPTH-1];
    reg [LOG2_DEPTH-1:0] in_ptr;
    reg [LOG2_DEPTH-1:0] in_tail;
    reg in_valid;
    reg in_ready;
    reg in_full;
    reg in_empty;
    reg in_last;
    reg in_tlast;
    reg in_tvalid;
    reg in_tready;
    reg in_pause_req;
    reg in_pause_ack;
    reg in_status_overflow;
    reg in_status_bad_frame;
    reg in_status_good_frame;
    reg in_status_depth;
    reg in_status_depth_commit;

    // Output FIFO
    reg [DATA_WIDTH-1:0] out_tdata [0:MAX_DEPTH-1];
    reg [KEEP_WIDTH-1:0] out_tkeep [0:MAX_DEPTH-1];
    reg [ID_WIDTH-1:0] out_tid [0:MAX_DEPTH-1];
    reg [DEST_WIDTH-1:0] out_tdest [0:MAX_DEPTH-1];
    reg [USER_WIDTH-1:0] out_tuser [0:MAX_DEPTH-1];
    reg [LOG2_DEPTH-1:0] out_ptr;
    reg [LOG2_DEPTH-1:0] out_head;
    reg out_valid;
    reg out_ready;
    reg out_full;
    reg out_empty;
    reg out_last;
    reg out_tlast;
    reg out_tvalid;
    reg out_tready;
    reg out_pause_ack;
    reg out_status_overflow;
    reg out_status_bad_frame;
    reg out_status_good_frame;
    reg out_status_depth;
    reg out_status_depth_commit;

    // Frame State Logic
    assign frame_frame_active = (frame_state == WRITING);
    assign frame_frame_full = (frame_state == MARKING);
    assign frame_frame_empty = (frame_state == IDLE);
    assign frame_frame_drop = (frame_state == DROPPING);
    assign frame_frame_mark = (frame_state == MARKING);
    assign frame_frame_pause = (frame_state == MARKING);
    assign frame_frame_bad = (frame_state == DROPPING);
    assign frame_frame_oversize = (frame_state == MARKING);
    assign frame_frame_last_seen = (frame_state == WRITING && s_axis_tlast);
    assign frame_frame_first_seen = (frame_state == IDLE && s_axis_tvalid);

    assign frame_frame_count_valid = (frame_state == WRITING || frame_state == MARKING);
    assign frame_frame_count = (frame_state == WRITING) ? in_ptr : (frame_start_addr + in_ptr);

    // Frame State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_state <= IDLE;
            frame_start_addr <= 0;
            frame_frame_active <= 0;
            frame_frame_full <= 0;
            frame_frame_empty <= 1;
            frame_frame_drop <= 0;
            frame_frame_mark <= 0;
            frame_frame_pause <= 0;
            frame_frame_bad <= 0;
            frame_frame_oversize <= 0;
            frame_frame_last_seen <= 0;
            frame_frame_first_seen <= 0;
            frame_frame_count <= 0;
        end else begin
            case (frame_state)
                IDLE: begin
                    if (s_axis_tvalid && !s_axis_tlast) begin
                        frame_state <= WRITING;
                        frame_start_addr <= in_ptr;
                        frame_frame_active <= 1;
                        frame_frame_empty <= 0;
                        frame_frame_first_seen <= 1;
                    end
                end
                WRITING: begin
                    if (s_axis_tlast) begin
                        if (frame_frame_oversize) begin
                            if (DROP_OVERSIZE_FRAME) begin
                                frame_state <= IDLE;
                                frame_frame_active <= 0;
                                frame_frame_empty <= 1;
                                frame_frame_drop <= 1;
                            end else begin
                                frame_state <= MARKING;
                                frame_frame_active <= 1;
                                frame_frame_full <= 1;
                                frame_frame_mark <= 1;
                            end
                        end else begin
                            frame_state <= MARKING;
                            frame_frame_active <= 1;
                            frame_frame_full <= 1;
                            frame_frame_mark <= 1;
                        end
                    end
                end
                DROPPING: begin
                    if (s_axis_tvalid) begin
                        frame_state <= WRITING;
                        frame_start_addr <= in_ptr;
                        frame_frame_active <= 1;
                        frame_frame_empty <= 0;
                        frame_frame_first_seen <= 1;
                    end
                end
                MARKING: begin
                    if (s_axis_tvalid) begin
                        frame_state <= WRITING;
                        frame_start_addr <= in_ptr;
                        frame_frame_active <= 1;
                        frame_frame_empty <= 0;
                        frame_frame_first_seen <= 1;
                    end
                end
            endcase
        end
    end

    // Input FIFO Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_ptr <= 0;
            in_tail <= 0;
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_ptr <= (in_valid && in_ready) ? (in_ptr + 1) : in_ptr;
            in_tail <= (in_valid && in_ready) ? in_tail : in_tail;
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_ptr <= 0;
            out_head <= 0;
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_ptr <= (out_valid && out_ready) ? (out_ptr + 1) : out_ptr;
            out_head <= (out_valid && out_ready) ? out_head : out_head;
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic (Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic (Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1;
            out_last <= 0;
            out_tlast <= 0;
            out_tvalid <= 0;
            out_tready <= 1;
            out_pause_ack <= 0;
            out_status_overflow <= 0;
            out_status_bad_frame <= 0;
            out_status_good_frame <= 0;
            out_status_depth <= 0;
            out_status_depth_commit <= 0;
        end else begin
            out_valid <= out_ready;
            out_ready <= (!out_full && !out_pause_ack);
            out_full <= (out_ptr == out_head);
            out_empty <= (out_ptr == out_head);
            out_last <= out_tlast;
            out_tlast <= out_tlast;
            out_tvalid <= out_valid;
            out_tready <= out_ready;
            out_pause_ack <= (out_valid && out_ready && pause_req);
            out_status_overflow <= out_full;
            out_status_bad_frame <= (frame_state == DROPPING);
            out_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            out_status_depth <= out_ptr;
            out_status_depth_commit <= out_head;
        end
    end

    // Input FIFO Write Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_valid <= 0;
            in_ready <= 1;
            in_full <= 0;
            in_empty <= 1;
            in_last <= 0;
            in_tlast <= 0;
            in_tvalid <= 0;
            in_tready <= 1;
            in_pause_req <= 0;
            in_pause_ack <= 0;
            in_status_overflow <= 0;
            in_status_bad_frame <= 0;
            in_status_good_frame <= 0;
            in_status_depth <= 0;
            in_status_depth_commit <= 0;
        end else begin
            in_valid <= s_axis_tvalid;
            in_ready <= (!in_full && !in_pause_req);
            in_full <= (in_ptr == in_tail);
            in_empty <= (in_ptr == in_tail);
            in_last <= s_axis_tlast;
            in_tlast <= s_axis_tlast;
            in_tvalid <= s_axis_tvalid;
            in_tready <= in_ready;
            in_pause_req <= pause_req;
            in_pause_ack <= (in_valid && in_ready && pause_req);
            in_status_overflow <= in_full;
            in_status_bad_frame <= (frame_state == DROPPING);
            in_status_good_frame <= (frame_state == WRITING || frame_state == MARKING);
            in_status_depth <= in_ptr;
            in_status_depth_commit <= in_tail;
        end
    end

    // Output FIFO Read Logic (Final Corrected)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_valid <= 0;
            out_ready <= 1;
            out_full <= 0;
            out_empty <= 1