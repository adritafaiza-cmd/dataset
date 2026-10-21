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
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    input  wire                   s_axis_tlast,
    input  wire [ID_WIDTH-1:0]    s_axis_tid,
    input  wire [DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [USER_WIDTH-1:0]  s_axis_tuser,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast,
    output wire [ID_WIDTH-1:0]    m_axis_tid,
    output wire [DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [USER_WIDTH-1:0]  m_axis_tuser,
    input  wire                   pause_req,
    output wire                   pause_ack,
    output wire [$clog2(DEPTH):0] status_depth,
    output wire [$clog2(DEPTH):0] status_depth_commit,
    output wire                   status_overflow,
    output wire                   status_bad_frame,
    output wire                   status_good_frame
);

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);

    // Internal signals for frame tracking
    reg [LOG2_DEPTH-1:0] frame_ptr;
    reg [LOG2_DEPTH-1:0] frame_ptr_commit;
    reg frame_valid;
    reg frame_last;
    reg frame_bad;
    reg frame_drop;
    reg frame_mark;
    reg frame_pause;
    reg frame_enable;

    // Output FIFO depth tracking
    reg [LOG2_DEPTH-1:0] out_fifo_depth;
    reg [LOG2_DEPTH-1:0] out_fifo_depth_commit;
    reg out_fifo_full;
    reg out_fifo_empty;

    // Pipeline registers for RAM output
    reg [DATA_WIDTH-1:0] ram_tdata;
    reg [KEEP_WIDTH-1:0] ram_tkeep;
    reg ram_tlast;
    reg ram_tid;
    reg ram_tdest;
    reg [USER_WIDTH-1:0] ram_tuser;
    reg ram_valid;

    // Frame state machine
    reg frame_state; // 0: Idle, 1: Collecting, 2: Finalizing
    reg frame_count;
    reg frame_enable_in;

    // Bad frame detection logic
    reg bad_frame_detected;
    reg bad_frame_mask;

    // Oversize detection
    reg oversize_detected;

    // Full/Mark logic
    reg full_marked;
    reg full_dropped;

    // Pause logic
    reg pause_pending;
    reg pause_ack_internal;

    // Output FIFO logic
    reg [DATA_WIDTH-1:0] out_tdata;
    reg [KEEP_WIDTH-1:0] out_tkeep;
    reg out_tlast;
    reg out_tid;
    reg out_tdest;
    reg [USER_WIDTH-1:0] out_tuser;
    reg out_valid;
    reg out_ready;

    // Frame FIFO logic
    reg [DATA_WIDTH-1:0] frame_tdata;
    reg [KEEP_WIDTH-1:0] frame_tkeep;
    reg frame_tlast;
    reg frame_tid;
    reg frame_tdest;
    reg [USER_WIDTH-1:0] frame_tuser;
    reg frame_valid;
    reg frame_ready;

    // RAM Write Enable
    reg [LOG2_DEPTH-1:0] ram_addr;
    reg ram_we;

    // Frame Enable Logic
    assign frame_enable = (s_axis_tvalid && s_axis_tready && s_axis_tkeep[0]);

    // Bad Frame Detection
    assign bad_frame_mask = (s_axis_tuser & USER_BAD_FRAME_MASK);
    assign bad_frame_detected = (bad_frame_mask == USER_BAD_FRAME_VALUE);

    // Oversize Detection
    assign oversize_detected = (frame_count > KEEP_WIDTH);

    // Full/Mark Logic
    assign full_marked = (MARK_WHEN_FULL && out_fifo_full);
    assign full_dropped = (DROP_WHEN_FULL && out_fifo_full);

    // Pause Logic
    assign pause_ack = (pause_pending && m_axis_tready);
    assign pause_pending = (PAUSE_ENABLE && pause_req && !m_axis_tready);

    // Frame FIFO Logic
    assign frame_ready = (!FRAME_FIFO || (frame_valid && m_axis_tready));

    // Output FIFO Logic
    assign out_ready = (!OUTPUT_FIFO_ENABLE || (out_valid && m_axis_tready));

    // Frame State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_state <= 0;
            frame_count <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            frame_state <= (frame_state == 2) ? 0 : 1;
            frame_count <= (frame_state == 1) ? frame_count + 1 : 0;
            frame_valid <= (frame_state == 2);
            frame_last <= s_axis_tlast;
            frame_bad <= bad_frame_detected;
            frame_drop <= full_dropped;
            frame_mark <= full_marked;
            frame_pause <= (FRAME_PAUSE && pause_pending);
            frame_enable_in <= frame_enable;
        end
    end

    // Frame FIFO Write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_tdata <= 0;
            frame_tkeep <= 0;
            frame_tlast <= 0;
            frame_tid <= 0;
            frame_tdest <= 0;
            frame_tuser <= 0;
            frame_valid <= 0;
            frame_ready <= 1;
        end else begin
            if (frame_enable_in && !frame_pause && !frame_drop && !frame_bad) begin
                if (frame_state == 1) begin
                    frame_tdata <= s_axis_tdata;
                    frame_tkeep <= s_axis_tkeep;
                    frame_tlast <= s_axis_tlast;
                    frame_tid <= s_axis_tid;
                    frame_tdest <= s_axis_tdest;
                    frame_tuser <= s_axis_tuser;
                    frame_valid <= 1;
                    frame_ready <= 0;
                end
            end else if (frame_state == 2 && frame_ready) begin
                frame_valid <= 0;
                frame_ready <= 1;
            end
        end
    end

    // Frame FIFO Read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_tdata <= 0;
            frame_tkeep <= 0;
            frame_tlast <= 0;
            frame_tid <= 0;
            frame_tdest <= 0;
            frame_tuser <= 0;
            frame_valid <= 0;
            frame_ready <= 1;
        end else begin
            if (FRAME_FIFO && frame_valid && m_axis_tready) begin
                frame_tdata <= frame_tdata;
                frame_tkeep <= frame_tkeep;
                frame_tlast <= frame_tlast;
                frame_tid <= frame_tid;
                frame_tdest <= frame_tdest;
                frame_tuser <= frame_tuser;
                frame_valid <= 0;
                frame_ready <= 1;
            end else begin
                frame_tdata <= 0;
                frame_tkeep <= 0;
                frame_tlast <= 0;
                frame_tid <= 0;
                frame_tdest <= 0;
                frame_tuser <= 0;
                frame_valid <= 0;
                frame_ready <= 1;
            end
        end
    end

    // RAM Write Enable
    assign ram_we = (s_axis_tvalid && s_axis_tready && s_axis_tkeep[0]);

    // RAM Address
    assign ram_addr = frame_ptr;

    // Frame Pointer Update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // RAM Read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_tdata <= 0;
            ram_tkeep <= 0;
            ram_tlast <= 0;
            ram_tid <= 0;
            ram_tdest <= 0;
            ram_tuser <= 0;
            ram_valid <= 0;
        end else begin
            if (frame_ptr_commit != frame_ptr) begin
                ram_tdata <= ram_tdata;
                ram_tkeep <= ram_tkeep;
                ram_tlast <= ram_tlast;
                ram_tid <= ram_tid;
                ram_tdest <= ram_tdest;
                ram_tuser <= ram_tuser;
                ram_valid <= 1;
            end else begin
                ram_tdata <= 0;
                ram_tkeep <= 0;
                ram_tlast <= 0;
                ram_tid <= 0;
                ram_tdest <= 0;
                ram_tuser <= 0;
                ram_valid <= 0;
            end
        end
    end

    // Output FIFO Write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_tdata <= 0;
            out_tkeep <= 0;
            out_tlast <= 0;
            out_tid <= 0;
            out_tdest <= 0;
            out_tuser <= 0;
            out_valid <= 0;
            out_ready <= 1;
        end else begin
            if (ram_valid && out_ready) begin
                out_tdata <= ram_tdata;
                out_tkeep <= ram_tkeep;
                out_tlast <= ram_tlast;
                out_tid <= ram_tid;
                out_tdest <= ram_tdest;
                out_tuser <= ram_tuser;
                out_valid <= 1;
                out_ready <= 0;
            end else begin
                out_tdata <= 0;
                out_tkeep <= 0;
                out_tlast <= 0;
                out_tid <= 0;
                out_tdest <= 0;
                out_tuser <= 0;
                out_valid <= 0;
                out_ready <= 1;
            end
        end
    end

    // Output FIFO Read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_tdata <= 0;
            out_tkeep <= 0;
            out_tlast <= 0;
            out_tid <= 0;
            out_tdest <= 0;
            out_tuser <= 0;
            out_valid <= 0;
            out_ready <= 1;
        end else begin
            if (out_valid && m_axis_tready) begin
                out_tdata <= out_tdata;
                out_tkeep <= out_tkeep;
                out_tlast <= out_tlast;
                out_tid <= out_tid;
                out_tdest <= out_tdest;
                out_tuser <= out_tuser;
                out_valid <= 0;
                out_ready <= 1;
            end else begin
                out_tdata <= 0;
                out_tkeep <= 0;
                out_tlast <= 0;
                out_tid <= 0;
                out_tdest <= 0;
                out_tuser <= 0;
                out_valid <= 0;
                out_ready <= 1;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end else begin
                out_fifo_depth <= out_fifo_depth;
                out_fifo_depth_commit <= out_fifo_depth_commit;
                out_fifo_full <= (out_fifo_depth == MAX_DEPTH);
                out_fifo_empty <= (out_fifo_depth == 0);
            end
        end
    end

    // Frame FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_ptr <= 0;
            frame_ptr_commit <= 0;
            frame_valid <= 0;
            frame_last <= 0;
            frame_bad <= 0;
            frame_drop <= 0;
            frame_mark <= 0;
            frame_pause <= 0;
            frame_enable_in <= 0;
        end else begin
            if (ram_we) begin
                frame_ptr <= frame_ptr + 1;
                frame_ptr_commit <= frame_ptr;
                frame_valid <= 1;
                frame_last <= s_axis_tlast;
                frame_bad <= bad_frame_detected;
                frame_drop <= full_dropped;
                frame_mark <= full_marked;
                frame_pause <= (FRAME_PAUSE && pause_pending);
                frame_enable_in <= frame_enable;
            end else begin
                frame_ptr <= frame_ptr;
                frame_ptr_commit <= frame_ptr_commit;
                frame_valid <= 0;
                frame_last <= 0;
                frame_bad <= 0;
                frame_drop <= 0;
                frame_mark <= 0;
                frame_pause <= 0;
                frame_enable_in <= 0;
            end
        end
    end

    // Output FIFO Depth Tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_fifo_depth <= 0;
            out_fifo_depth_commit <= 0;
            out_fifo_full <= 0;
            out_fifo_empty <= 1;
        end else begin
            if (out_valid && out_ready) begin
                out_fifo_depth <= out_fifo_depth + 1;
                out_fifo_depth_commit <= out_fifo_depth;
                out_fifo_full <= (out_fifo_depth == MAX