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

    localparam LOG2_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);

    // Internal signals for pipeline stages
    reg [LOG2_DEPTH:0] wr_ptr, rd_ptr;
    reg [LOG2_DEPTH:0] wr_ptr_commit, rd_ptr_commit;
    reg [LOG2_DEPTH:0] wr_ptr_next, rd_ptr_next;
    reg [LOG2_DEPTH:0] wr_ptr_next_commit, rd_ptr_next_commit;
    
    reg [DATA_WIDTH-1:0] ram_data [0:MAX_DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:MAX_DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:MAX_DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:MAX_DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:MAX_DEPTH-1];
    reg ram_last [0:MAX_DEPTH-1];
    reg ram_valid [0:MAX_DEPTH-1];
    reg ram_pause [0:MAX_DEPTH-1];
    reg ram_bad_frame [0:MAX_DEPTH-1];
    reg ram_oversize [0:MAX_DEPTH-1];
    
    reg [LOG2_DEPTH:0] wr_ptr_ram, rd_ptr_ram;
    reg [LOG2_DEPTH:0] wr_ptr_ram_commit, rd_ptr_ram_commit;
    reg [LOG2_DEPTH:0] wr_ptr_ram_next, rd_ptr_ram_next;
    
    reg [DATA_WIDTH-1:0] out_data;
    reg [KEEP_WIDTH-1:0] out_keep;
    reg out_last;
    reg out_valid;
    reg out_id;
    reg out_dest;
    reg out_user;
    reg out_pause;
    reg out_bad_frame;
    reg out_oversize;
    
    reg [LOG2_DEPTH:0] out_ptr;
    reg [LOG2_DEPTH:0] out_ptr_commit;
    reg [LOG2_DEPTH:0] out_ptr_next;
    
    reg [LOG2_DEPTH:0] depth_reg;
    reg [LOG2_DEPTH:0] depth_commit_reg;
    reg overflow_reg;
    reg bad_frame_reg;
    reg good_frame_reg;
    reg pause_ack_reg;
    reg pause_req_reg;
    
    reg [LOG2_DEPTH:0] depth_reg_next, depth_commit_reg_next;
    reg overflow_reg_next;
    reg bad_frame_reg_next;
    reg good_frame_reg_next;
    reg pause_ack_reg_next;
    reg pause_req_reg_next;

    // Pipeline registers for write pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            wr_ptr_commit <= '0;
            wr_ptr_next <= '0;
            wr_ptr_next_commit <= '0;
        end else begin
            wr_ptr <= wr_ptr_next;
            wr_ptr_commit <= wr_ptr_next_commit;
            wr_ptr_next <= wr_ptr;
            wr_ptr_next_commit <= wr_ptr_commit;
        end
    end

    // Pipeline registers for read pointer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= '0;
            rd_ptr_commit <= '0;
            rd_ptr_next <= '0;
            rd_ptr_next_commit <= '0;
        end else begin
            rd_ptr <= rd_ptr_next;
            rd_ptr_commit <= rd_ptr_next_commit;
            rd_ptr_next <= rd_ptr;
            rd_ptr_next_commit <= rd_ptr_commit;
        end
    end

    // Pipeline registers for RAM pointers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_ram <= '0;
            rd_ptr_ram <= '0;
            wr_ptr_ram_commit <= '0;
            rd_ptr_ram_commit <= '0;
            wr_ptr_ram_next <= '0;
            rd_ptr_ram_next <= '0;
        end else begin
            wr_ptr_ram <= wr_ptr_ram_next;
            rd_ptr_ram <= rd_ptr_ram_next;
            wr_ptr_ram_commit <= wr_ptr_ram_next_commit;
            rd_ptr_ram_commit <= rd_ptr_ram_next_commit;
            wr_ptr_ram_next <= wr_ptr_ram;
            rd_ptr_ram_next <= rd_ptr_ram;
        end
    end

    // Pipeline registers for output data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_data <= '0;
            out_keep <= '0;
            out_last <= 1'b0;
            out_valid <= 1'b0;
            out_id <= '0;
            out_dest <= '0;
            out_user <= '0;
            out_pause <= 1'b0;
            out_bad_frame <= 1'b0;
            out_oversize <= 1'b0;
            out_ptr <= '0;
            out_ptr_commit <= '0;
            out_ptr_next <= '0;
        end else begin
            out_data <= out_data; // Hold
            out_keep <= out_keep;
            out_last <= out_last;
            out_valid <= out_valid;
            out_id <= out_id;
            out_dest <= out_dest;
            out_user <= out_user;
            out_pause <= out_pause;
            out_bad_frame <= out_bad_frame;
            out_oversize <= out_oversize;
            out_ptr <= out_ptr_next;
            out_ptr_commit <= out_ptr_next_commit;
            out_ptr_next <= out_ptr;
        end
    end

    // Pipeline registers for status
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            depth_reg <= '0;
            depth_commit_reg <= '0;
            overflow_reg <= 1'b0;
            bad_frame_reg <= 1'b0;
            good_frame_reg <= 1'b0;
            pause_ack_reg <= 1'b0;
            pause_req_reg <= 1'b0;
            depth_reg_next <= '0;
            depth_commit_reg_next <= '0;
            overflow_reg_next <= 1'b0;
            bad_frame_reg_next <= 1'b0;
            good_frame_reg_next <= 1'b0;
            pause_ack_reg_next <= 1'b0;
            pause_req_reg_next <= 1'b0;
        end else begin
            depth_reg <= depth_reg_next;
            depth_commit_reg <= depth_commit_reg_next;
            overflow_reg <= overflow_reg_next;
            bad_frame_reg <= bad_frame_reg_next;
            good_frame_reg <= good_frame_reg_next;
            pause_ack_reg <= pause_ack_reg_next;
            pause_req_reg <= pause_req_reg_next;
            depth_reg_next <= depth_reg;
            depth_commit_reg_next <= depth_commit_reg;
            overflow_reg_next <= overflow_reg;
            bad_frame_reg_next <= bad_frame_reg;
            good_frame_reg_next <= good_frame_reg;
            pause_ack_reg_next <= pause_ack_reg;
            pause_req_reg_next <= pause_req_reg;
        end
    end

    // Write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_ram_next <= '0;
            depth_reg_next <= '0;
            overflow_reg_next <= 1'b0;
            bad_frame_reg_next <= 1'b0;
            good_frame_reg_next <= 1'b0;
        end else begin
            wr_ptr_ram_next <= wr_ptr_ram;
            
            if (s_axis_tvalid && s_axis_tready) begin
                if (DROP_WHEN_FULL && (depth_reg == MAX_DEPTH - 1)) begin
                    overflow_reg_next <= 1'b1;
                    depth_reg_next <= depth_reg;
                    bad_frame_reg_next <= 1'b0;
                    good_frame_reg_next <= 1'b0;
                end else begin
                    depth_reg_next <= depth_reg + 1'b1;
                    overflow_reg_next <= 1'b0;
                    
                    if (FRAME_FIFO && s_axis_tlast) begin
                        if (depth_reg == MAX_DEPTH - 1) begin
                            if (DROP_OVERSIZE_FRAME) begin
                                overflow_reg_next <= 1'b1;
                                depth_reg_next <= depth_reg;
                                bad_frame_reg_next <= 1'b0;
                                good_frame_reg_next <= 1'b0;
                            end else begin
                                depth_reg_next <= depth_reg + 1'b1;
                                overflow_reg_next <= 1'b0;
                            end
                        end else begin
                            depth_reg_next <= depth_reg + 1'b1;
                            overflow_reg_next <= 1'b0;
                        end
                    end else begin
                        depth_reg_next <= depth_reg + 1'b1;
                        overflow_reg_next <= 1'b0;
                    end
                    
                    if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                        bad_frame_reg_next <= 1'b1;
                        good_frame_reg_next <= 1'b0;
                    end else begin
                        bad_frame_reg_next <= 1'b0;
                        good_frame_reg_next <= 1'b1;
                    end
                end
            end else begin
                overflow_reg_next <= 1'b0;
                bad_frame_reg_next <= 1'b0;
                good_frame_reg_next <= 1'b0;
            end
        end
    end

    // Read logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr_ram_next <= '0;
            depth_commit_reg_next <= '0;
            pause_ack_reg_next <= 1'b0;
            pause_req_reg_next <= 1'b0;
        end else begin
            rd_ptr_ram_next <= rd_ptr_ram;
            
            if (m_axis_tready && (depth_reg > 0)) begin
                if (FRAME_FIFO && s_axis_tlast) begin
                    if (depth_reg == 1) begin
                        depth_commit_reg_next <= '0;
                        pause_ack_reg_next <= 1'b0;
                        pause_req_reg_next <= 1'b0;
                    end else begin
                        depth_commit_reg_next <= depth_reg - 1'b1;
                        pause_ack_reg_next <= 1'b0;
                        pause_req_reg_next <= 1'b0;
                    end
                end else begin
                    if (OUTPUT_FIFO_ENABLE && (depth_reg == 1)) begin
                        depth_commit_reg_next <= '0;
                        pause_ack_reg_next <= 1'b0;
                        pause_req_reg_next <= 1'b0;
                    end else begin
                        depth_commit_reg_next <= depth_reg - 1'b1;
                        pause_ack_reg_next <= 1'b0;
                        pause_req_reg_next <= 1'b0;
                    end
                end
            end else begin
                depth_commit_reg_next <= depth_commit_reg;
                pause_ack_reg_next <= pause_ack_reg;
                pause_req_reg_next <= pause_req_reg;
            end
        end
    end

    // RAM Write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data <= '0;
            ram_keep <= '0;
            ram_id <= '0;
            ram_dest <= '0;
            ram_user <= '0;
            ram_last <= 1'b0;
            ram_valid <= 1'b0;
            ram_pause <= 1'b0;
            ram_bad_frame <= 1'b0;
            ram_oversize <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                ram_data[wr_ptr_ram] <= s_axis_tdata;
                ram_keep[wr_ptr_ram] <= s_axis_tkeep;
                ram_id[wr_ptr_ram] <= s_axis_tid;
                ram_dest[wr_ptr_ram] <= s_axis_tdest;
                ram_user[wr_ptr_ram] <= s_axis_tuser;
                ram_last[wr_ptr_ram] <= s_axis_tlast;
                ram_valid[wr_ptr_ram] <= 1'b1;
                ram_pause[wr_ptr_ram] <= 1'b0;
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // RAM Read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out_data <= '0;
            out_keep <= '0;
            out_last <= 1'b0;
            out_valid <= 1'b0;
            out_id <= '0;
            out_dest <= '0;
            out_user <= '0;
            out_pause <= 1'b0;
            out_bad_frame <= 1'b0;
            out_oversize <= 1'b0;
            out_ptr <= '0;
            out_ptr_commit <= '0;
            out_ptr_next <= '0;
        end else begin
            if (m_axis_tready && (depth_reg > 0)) begin
                out_ptr <= rd_ptr_ram;
                out_data <= ram_data[rd_ptr_ram];
                out_keep <= ram_keep[rd_ptr_ram];
                out_last <= ram_last[rd_ptr_ram];
                out_id <= ram_id[rd_ptr_ram];
                out_dest <= ram_dest[rd_ptr_ram];
                out_user <= ram_user[rd_ptr_ram];
                out_pause <= ram_pause[rd_ptr_ram];
                out_bad_frame <= ram_bad_frame[rd_ptr_ram];
                out_oversize <= ram_oversize[rd_ptr_ram];
                out_valid <= 1'b1;
            end else begin
                out_ptr <= '0;
                out_data <= '0;
                out_keep <= '0;
                out_last <= 1'b0;
                out_id <= '0;
                out_dest <= '0;
                out_user <= '0;
                out_pause <= 1'b0;
                out_bad_frame <= 1'b0;
                out_oversize <= 1'b0;
                out_valid <= 1'b0;
            end
        end
    end

    // Output Assignment
    assign s_axis_tready = (depth_reg < MAX_DEPTH) || (DROP_WHEN_FULL && (depth_reg == MAX_DEPTH - 1));
    assign m_axis_tdata = out_data;
    assign m_axis_tkeep = out_keep;
    assign m_axis_tvalid = out_valid;
    assign m_axis_tlast = out_last;
    assign m_axis_tid = out_id;
    assign m_axis_tdest = out_dest;
    assign m_axis_tuser = out_user;
    assign pause_ack = pause_ack_reg;
    assign status_depth = depth_reg;
    assign status_depth_commit = depth_commit_reg;
    assign status_overflow = overflow_reg;
    assign status_bad_frame = bad_frame_reg;
    assign status_good_frame = good_frame_reg;

    // Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_ack_reg <= 1'b0;
            pause_req_reg <= 1'b0;
        end else begin
            pause_ack_reg <= pause_ack_reg_next;
            pause_req_reg <= pause_req_reg_next;
            
            if (PAUSE_ENABLE && FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    pause_ack_reg <= 1'b1;
                end else begin
                    pause_ack_reg <= 1'b0;
                end
            end else begin
                pause_ack_reg <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pause_ack_reg <= 1'b0;
            pause_req_reg <= 1'b0;
        end else begin
            pause_ack_reg <= pause_ack_reg_next;
            pause_req_reg <= pause_req_reg_next;
            
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    pause_ack_reg <= 1'b1;
                end else begin
                    pause_ack_reg <= 1'b0;
                end
            end else begin
                pause_ack_reg <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end else begin
            if (FRAME_FIFO && s_axis_tlast) begin
                if (depth_reg == MAX_DEPTH - 1) begin
                    ram_oversize[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_oversize[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_oversize[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Bad Frame Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_bad_frame <= '0;
        end else begin
            if (DROP_BAD_FRAME && (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE) begin
                ram_bad_frame[wr_ptr_ram] <= 1'b1;
            end else begin
                ram_bad_frame[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Pause Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_pause <= '0;
        end else begin
            if (FRAME_PAUSE && s_axis_tlast) begin
                if (depth_reg > 0) begin
                    ram_pause[wr_ptr_ram] <= 1'b1;
                end else begin
                    ram_pause[wr_ptr_ram] <= 1'b0;
                end
            end else begin
                ram_pause[wr_ptr_ram] <= 1'b0;
            end
        end
    end

    // Frame Oversize Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_oversize <= '0;
        end