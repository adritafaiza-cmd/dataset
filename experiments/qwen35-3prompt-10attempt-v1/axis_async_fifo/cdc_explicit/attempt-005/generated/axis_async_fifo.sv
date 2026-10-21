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
    localparam MAX_DEPTH = (1 << LOG2_DEPTH);
    
    // Internal signals for CDC
    wire [LOG2_DEPTH:0] s_ptr, m_ptr;
    wire [LOG2_DEPTH:0] s_ptr_commit, m_ptr_commit;
    wire s_empty, s_full, m_empty, m_full;
    wire s_empty_commit, s_full_commit, m_empty_commit, m_full_commit;
    
    // Frame state
    wire s_frame_valid, m_frame_valid;
    wire s_frame_commit, m_frame_commit;
    wire s_frame_done, m_frame_done;
    wire s_frame_bad, m_frame_bad;
    wire s_frame_oversize, m_frame_oversize;
    wire s_pause, m_pause;
    
    // Pipeline registers for data
    wire [DATA_WIDTH-1:0] s_tdata_reg, m_tdata_reg;
    wire [KEEP_WIDTH-1:0] s_tkeep_reg, m_tkeep_reg;
    wire s_tlast_reg, m_tlast_reg;
    wire [ID_WIDTH-1:0] s_tid_reg, m_tid_reg;
    wire [DEST_WIDTH-1:0] s_tdest_reg, m_tdest_reg;
    wire [USER_WIDTH-1:0] s_tuser_reg, m_tuser_reg;
    wire s_tvalid_reg, m_tvalid_reg;
    wire s_tready_reg, m_tready_reg;
    
    // Bad frame flag
    wire s_bad_frame_flag, m_bad_frame_flag;
    wire s_oversize_flag, m_oversize_flag;

    // ---------------------------------------------------------
    // CDC: Pointer and Status Registers
    // ---------------------------------------------------------
    
    // Source Domain Pointers
    reg [LOG2_DEPTH:0] s_ptr_reg, s_ptr_commit_reg;
    reg s_empty_reg, s_full_reg;
    reg s_empty_commit_reg, s_full_commit_reg;
    reg s_frame_valid_reg, s_frame_commit_reg;
    reg s_frame_done_reg, s_frame_bad_reg;
    reg s_frame_oversize_reg;
    reg s_pause_reg;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_ptr_reg <= 0;
            s_ptr_commit_reg <= 0;
            s_empty_reg <= 1;
            s_full_reg <= 0;
            s_empty_commit_reg <= 1;
            s_full_commit_reg <= 0;
            s_frame_valid_reg <= 0;
            s_frame_commit_reg <= 0;
            s_frame_done_reg <= 0;
            s_frame_bad_reg <= 0;
            s_frame_oversize_reg <= 0;
            s_pause_reg <= 0;
        end else begin
            s_ptr_reg <= s_ptr_reg + 1'b1;
            s_ptr_commit_reg <= s_ptr_reg;
            s_empty_reg <= (s_ptr_reg == 0);
            s_full_reg <= (s_ptr_reg == MAX_DEPTH);
            s_empty_commit_reg <= s_ptr_commit_reg;
            s_full_commit_reg <= s_ptr_commit_reg;
            s_frame_valid_reg <= s_frame_valid_reg;
            s_frame_commit_reg <= s_frame_commit_reg;
            s_frame_done_reg <= s_frame_done_reg;
            s_frame_bad_reg <= s_frame_bad_reg;
            s_frame_oversize_reg <= s_frame_oversize_reg;
            s_pause_reg <= s_pause_reg;
        end
    end

    // Master Domain Pointers
    reg [LOG2_DEPTH:0] m_ptr_reg, m_ptr_commit_reg;
    reg m_empty_reg, m_full_reg;
    reg m_empty_commit_reg, m_full_commit_reg;
    reg m_frame_valid_reg, m_frame_commit_reg;
    reg m_frame_done_reg, m_frame_bad_reg;
    reg m_frame_oversize_reg;
    reg m_pause_reg;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_ptr_reg <= 0;
            m_ptr_commit_reg <= 0;
            m_empty_reg <= 1;
            m_full_reg <= 0;
            m_empty_commit_reg <= 1;
            m_full_commit_reg <= 0;
            m_frame_valid_reg <= 0;
            m_frame_commit_reg <= 0;
            m_frame_done_reg <= 0;
            m_frame_bad_reg <= 0;
            m_frame_oversize_reg <= 0;
            m_pause_reg <= 0;
        end else begin
            m_ptr_reg <= m_ptr_reg + 1'b1;
            m_ptr_commit_reg <= m_ptr_reg;
            m_empty_reg <= (m_ptr_reg == 0);
            m_full_reg <= (m_ptr_reg == MAX_DEPTH);
            m_empty_commit_reg <= m_ptr_commit_reg;
            m_full_commit_reg <= m_ptr_commit_reg;
            m_frame_valid_reg <= m_frame_valid_reg;
            m_frame_commit_reg <= m_frame_commit_reg;
            m_frame_done_reg <= m_frame_done_reg;
            m_frame_bad_reg <= m_frame_bad_reg;
            m_frame_oversize_reg <= m_frame_oversize_reg;
            m_pause_reg <= m_pause_reg;
        end
    end

    // ---------------------------------------------------------
    // CDC: Cross-Clock Handshakes
    // ---------------------------------------------------------
    
    // s_axis_tready generation (Master -> Source)
    // Ready if FIFO not full AND (not paused OR pause ack logic handled)
    // We use a simple cross-clock register for the ready signal logic
    wire s_ready_logic;
    assign s_ready_logic = (!m_full && !m_pause);
    
    reg s_tready_reg;
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst)
            s_tready_reg <= 1'b1;
        else
            s_tready_reg <= s_ready_logic;
    end
    assign s_axis_tready = s_tready_reg;

    // m_axis_tvalid generation (Source -> Master)
    // Valid if FIFO not empty AND (not paused OR pause ack logic handled)
    wire m_valid_logic;
    assign m_valid_logic = (!s_empty && !s_pause);
    
    reg m_tvalid_reg;
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst)
            m_tvalid_reg <= 1'b0;
        else
            m_tvalid_reg <= m_valid_logic;
    end
    assign m_axis_tvalid = m_tvalid_reg;

    // ---------------------------------------------------------
    // CDC: Data Transfer
    // ---------------------------------------------------------
    
    // Capture input data on s_clk
    reg [DATA_WIDTH-1:0] s_tdata_capture;
    reg [KEEP_WIDTH-1:0] s_tkeep_capture;
    reg s_tlast_capture;
    reg [ID_WIDTH-1:0] s_tid_capture;
    reg [DEST_WIDTH-1:0] s_tdest_capture;
    reg [USER_WIDTH-1:0] s_tuser_capture;
    reg s_tvalid_capture;
    reg s_tready_capture;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_tdata_capture <= 0;
            s_tkeep_capture <= 0;
            s_tlast_capture <= 0;
            s_tid_capture <= 0;
            s_tdest_capture <= 0;
            s_tuser_capture <= 0;
            s_tvalid_capture <= 0;
            s_tready_capture <= 0;
        end else begin
            s_tdata_capture <= s_axis_tdata;
            s_tkeep_capture <= s_axis_tkeep;
            s_tlast_capture <= s_axis_tlast;
            s_tid_capture <= s_axis_tid;
            s_tdest_capture <= s_axis_tdest;
            s_tuser_capture <= s_axis_tuser;
            s_tvalid_capture <= s_axis_tvalid;
            s_tready_capture <= s_axis_tready;
        end
    end

    // Output data on m_clk
    reg [DATA_WIDTH-1:0] m_tdata_out;
    reg [KEEP_WIDTH-1:0] m_tkeep_out;
    reg m_tlast_out;
    reg [ID_WIDTH-1:0] m_tid_out;
    reg [DEST_WIDTH-1:0] m_tdest_out;
    reg [USER_WIDTH-1:0] m_tuser_out;
    reg m_tvalid_out;
    reg m_tready_out;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_tdata_out <= 0;
            m_tkeep_out <= 0;
            m_tlast_out <= 0;
            m_tid_out <= 0;
            m_tdest_out <= 0;
            m_tuser_out <= 0;
            m_tvalid_out <= 0;
            m_tready_out <= 0;
        end else begin
            m_tdata_out <= s_tdata_capture;
            m_tkeep_out <= s_tkeep_capture;
            m_tlast_out <= s_tlast_capture;
            m_tid_out <= s_tid_capture;
            m_tdest_out <= s_tdest_capture;
            m_tuser_out <= s_tuser_capture;
            m_tvalid_out <= s_tvalid_capture;
            m_tready_out <= s_tready_capture;
        end
    end

    // ---------------------------------------------------------
    // CDC: Frame State Transfer
    // ---------------------------------------------------------
    
    // Capture frame state on s_clk
    reg s_frame_valid_capture;
    reg s_frame_commit_capture;
    reg s_frame_done_capture;
    reg s_frame_bad_capture;
    reg s_frame_oversize_capture;
    reg s_pause_capture;
    
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_valid_capture <= 0;
            s_frame_commit_capture <= 0;
            s_frame_done_capture <= 0;
            s_frame_bad_capture <= 0;
            s_frame_oversize_capture <= 0;
            s_pause_capture <= 0;
        end else begin
            s_frame_valid_capture <= s_frame_valid;
            s_frame_commit_capture <= s_frame_commit;
            s_frame_done_capture <= s_frame_done;
            s_frame_bad_capture <= s_frame_bad;
            s_frame_oversize_capture <= s_frame_oversize;
            s_pause_capture <= s_pause;
        end
    end

    // Output frame state on m_clk
    reg m_frame_valid_out;
    reg m_frame_commit_out;
    reg m_frame_done_out;
    reg m_frame_bad_out;
    reg m_frame_oversize_out;
    reg m_pause_out;
    
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_valid_out <= 0;
            m_frame_commit_out <= 0;
            m_frame_done_out <= 0;
            m_frame_bad_out <= 0;
            m_frame_oversize_out <= 0;
            m_pause_out <= 0;
        end else begin
            m_frame_valid_out <= s_frame_valid_capture;
            m_frame_commit_out <= s_frame_commit_capture;
            m_frame_done_out <= s_frame_done_capture;
            m_frame_bad_out <= s_frame_bad_capture;
            m_frame_oversize_out <= s_frame_oversize_capture;
            m_pause_out <= s_pause_capture;
        end
    end

    // ---------------------------------------------------------
    // Source Domain Logic
    // ---------------------------------------------------------
    
    // Frame State Machine
    assign s_frame_valid = s_frame_valid_reg;
    assign s_frame_commit = s_frame_commit_reg;
    assign s_frame_done = s_frame_done_reg;
    assign s_frame_bad = s_frame_bad_reg;
    assign s_frame_oversize = s_frame_oversize_reg;
    assign s_pause = s_pause_reg;

    // Frame State Updates
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_frame_valid_reg <= 0;
            s_frame_commit_reg <= 0;
            s_frame_done_reg <= 0;
            s_frame_bad_reg <= 0;
            s_frame_oversize_reg <= 0;
        end else begin
            // Frame start
            if (s_axis_tvalid && s_axis_tready && !s_frame_valid_reg) begin
                s_frame_valid_reg <= 1;
                s_frame_commit_reg <= 0;
                s_frame_done_reg <= 0;
                s_frame_bad_reg <= 0;
                s_frame_oversize_reg <= 0;
            end
            // Frame commit
            else if (s_frame_valid_reg && s_axis_tlast && s_axis_tready) begin
                s_frame_valid_reg <= 0;
                s_frame_commit_reg <= 1;
                s_frame_done_reg <= 0;
                s_frame_bad_reg <= 0;
                s_frame_oversize_reg <= 0;
            end
            // Frame done
            else if (s_frame_commit_reg && s_axis_tready) begin
                s_frame_commit_reg <= 0;
                s_frame_done_reg <= 1;
                s_frame_bad_reg <= 0;
                s_frame_oversize_reg <= 0;
            end
            // Frame bad/oversize detection
            else if (s_frame_valid_reg && s_axis_tready) begin
                if (DROP_OVERSIZE_FRAME && s_frame_oversize) begin
                    s_frame_bad_reg <= 1;
                end
                if (DROP_BAD_FRAME && s_frame_bad) begin
                    s_frame_bad_reg <= 1;
                end
            end
            // Frame done reset
            else if (s_frame_done_reg && s_axis_tready) begin
                s_frame_done_reg <= 0;
            end
        end
    end

    // Pause Logic
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            s_pause_reg <= 0;
            s_pause_ack <= 0;
        end else begin
            if (s_pause_req && !s_pause_reg) begin
                s_pause_reg <= 1;
                s_pause_ack <= 1;
            end else if (!s_pause_req && s_pause_reg) begin
                s_pause_reg <= 0;
                s_pause_ack <= 0;
            end else begin
                s_pause_ack <= 0;
            end
        end
    end

    // Bad Frame Logic
    wire s_bad_frame_input = (s_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    wire s_oversize_input = (s_axis_tkeep == {KEEP_WIDTH{1'b0}} && s_axis_tvalid && s_axis_tready); // Simplified oversize check
    
    // ---------------------------------------------------------
    // Master Domain Logic
    // ---------------------------------------------------------
    
    // Frame State Machine
    assign m_frame_valid = m_frame_valid_out;
    assign m_frame_commit = m_frame_commit_out;
    assign m_frame_done = m_frame_done_out;
    assign m_frame_bad = m_frame_bad_out;
    assign m_frame_oversize = m_frame_oversize_out;
    assign m_pause = m_pause_out;

    // Frame State Updates
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_frame_valid_reg <= 0;
            m_frame_commit_reg <= 0;
            m_frame_done_reg <= 0;
            m_frame_bad_reg <= 0;
            m_frame_oversize_reg <= 0;
        end else begin
            // Frame start
            if (m_axis_tvalid && m_axis_tready && !m_frame_valid_reg) begin
                m_frame_valid_reg <= 1;
                m_frame_commit_reg <= 0;
                m_frame_done_reg <= 0;
                m_frame_bad_reg <= 0;
                m_frame_oversize_reg <= 0;
            end
            // Frame commit
            else if (m_frame_valid_reg && m_axis_tlast && m_axis_tready) begin
                m_frame_valid_reg <= 0;
                m_frame_commit_reg <= 1;
                m_frame_done_reg <= 0;
                m_frame_bad_reg <= 0;
                m_frame_oversize_reg <= 0;
            end
            // Frame done
            else if (m_frame_commit_reg && m_axis_tready) begin
                m_frame_commit_reg <= 0;
                m_frame_done_reg <= 1;
                m_frame_bad_reg <= 0;
                m_frame_oversize_reg <= 0;
            end
            // Frame bad/oversize detection
            else if (m_frame_valid_reg && m_axis_tready) begin
                if (DROP_OVERSIZE_FRAME && m_frame_oversize) begin
                    m_frame_bad_reg <= 1;
                end
                if (DROP_BAD_FRAME && m_frame_bad) begin
                    m_frame_bad_reg <= 1;
                end
            end
            // Frame done reset
            else if (m_frame_done_reg && m_axis_tready) begin
                m_frame_done_reg <= 0;
            end
        end
    end

    // Pause Logic
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_pause_reg <= 0;
            m_pause_ack <= 0;
        end else begin
            if (m_pause_req && !m_pause_reg) begin
                m_pause_reg <= 1;
                m_pause_ack <= 1;
            end else if (!m_pause_req && m_pause_reg) begin
                m_pause_reg <= 0;
                m_pause_ack <= 0;
            end else begin
                m_pause_ack <= 0;
            end
        end
    end

    // Bad Frame Logic
    wire m_bad_frame_input = (m_axis_tuser & USER_BAD_FRAME_MASK) == USER_BAD_FRAME_VALUE;
    wire m_oversize_input = (m_axis_tkeep == {KEEP_WIDTH{1'b0}} && m_axis_tvalid && m_axis_tready); // Simplified oversize check

    // ---------------------------------------------------------
    // Output Logic
    // ---------------------------------------------------------
    
    assign m_axis_tdata = m_tdata_out;
    assign m_axis_tkeep = m_tkeep_out;
    assign m_axis_tvalid = m_tvalid_out;
    assign m_axis_tlast = m_tlast_out;
    assign m_axis_tid = m_tid_out;
    assign m_axis_tdest = m_tdest_out;
    assign m_axis_tuser = m_tuser_out;
    assign m_axis_tready = m_axis_tready; // Pass through

    // Status Outputs
    assign s_status_depth = s_ptr_reg;
    assign s_status_depth_commit = s_ptr_commit_reg;
    assign s_status_overflow = s_full_reg;
    assign s_status_bad_frame = s_frame_bad_reg;
    assign s_status_good_frame = s_frame_done_reg;
    
    assign m_status_depth = m_ptr_reg;
    assign m_status_depth_commit = m_ptr_commit_reg;
    assign m_status_overflow = m_full_reg;
    assign m_status_bad_frame = m_frame_bad_reg;
    assign m_status_good_frame = m_frame_done_reg;

endmodule
```<|im_end|>
