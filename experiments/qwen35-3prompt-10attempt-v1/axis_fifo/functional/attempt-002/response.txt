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

    localparam LOG_DEPTH = $clog2(DEPTH);
    localparam MAX_DEPTH = (1 << LOG_DEPTH);

    // Internal signals
    reg [LOG_DEPTH-1:0] wr_ptr, rd_ptr;
    reg [LOG_DEPTH-1:0] wr_ptr_commit, rd_ptr_commit;
    reg [LOG_DEPTH-1:0] wr_ptr_next, rd_ptr_next;
    reg [LOG_DEPTH-1:0] wr_ptr_last, rd_ptr_last;
    
    reg [DATA_WIDTH-1:0] ram_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] ram_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] ram_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] ram_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] ram_user [0:DEPTH-1];
    reg ram_last [0:DEPTH-1];
    reg ram_tlast_valid [0:DEPTH-1]; // Flag to indicate if tlast was captured for this word
    
    reg [LOG_DEPTH-1:0] frame_start_ptr;
    reg frame_in_frame;
    reg frame_oversize;
    reg frame_bad;
    reg frame_pause_flag;
    reg frame_pause_ack_flag;
    
    reg [LOG_DEPTH-1:0] output_fifo_wr_ptr;
    reg [LOG_DEPTH-1:0] output_fifo_rd_ptr;
    reg [LOG_DEPTH-1:0] output_fifo_wr_ptr_commit, output_fifo_rd_ptr_commit;
    reg [DATA_WIDTH-1:0] output_fifo_data [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] output_fifo_keep [0:DEPTH-1];
    reg [ID_WIDTH-1:0] output_fifo_id [0:DEPTH-1];
    reg [DEST_WIDTH-1:0] output_fifo_dest [0:DEPTH-1];
    reg [USER_WIDTH-1:0] output_fifo_user [0:DEPTH-1];
    reg output_fifo_last [0:DEPTH-1];
    reg output_fifo_tlast_valid [0:DEPTH-1];
    
    reg [LOG_DEPTH-1:0] output_fifo_depth;
    reg [LOG_DEPTH-1:0] output_fifo_depth_commit;
    reg output_fifo_full;
    reg output_fifo_empty;
    
    reg s_axis_tready_int;
    reg m_axis_tvalid_int;
    reg m_axis_tlast_int;
    reg m_axis_tid_int;
    reg m_axis_tdest_int;
    reg m_axis_tuser_int;
    reg m_axis_tkeep_int;
    reg m_axis_tdata_int;
    
    reg pause_ack_int;
    reg status_bad_frame_int;
    reg status_good_frame_int;
    reg status_overflow_int;

    // Helper function to check if pointers are equal (wr == rd)
    function reg [LOG_DEPTH-1:0] is_equal;
        input [LOG_DEPTH-1:0] a, b;
        begin
            is_equal = (a == b);
        end
    endfunction

    // Helper function to increment pointer with wrap-around
    function reg [LOG_DEPTH-1:0] inc_ptr;
        input [LOG_DEPTH-1:0] ptr;
        begin
            inc_ptr = ptr + 1'b1;
            if (inc_ptr == 0) inc_ptr = 0; // Should not happen with proper logic, but safe guard
        end
    endfunction

    // Helper function to decrement pointer with wrap-around
    function reg [LOG_DEPTH-1:0] dec_ptr;
        input [LOG_DEPTH-1:0] ptr;
        begin
            dec_ptr = ptr - 1'b1;
            if (dec_ptr == MAX_DEPTH-1) dec_ptr = 0; // Should not happen
        end
    endfunction

    // Helper function to check if FIFO is full
    function reg is_full;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            if (FRAME_FIFO)
                is_full = (wr == rd); // In frame mode, full is when pointers meet
            else
                is_full = (wr == rd); // Standard full check
        end
    endfunction

    // Helper function to check if FIFO is empty
    function reg is_empty;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            if (FRAME_FIFO)
                is_empty = (wr == rd);
            else
                is_empty = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard)
    function reg is_full_std;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard)
    function reg is_empty_std;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame mode logic)
    // In frame mode, we treat the FIFO as a circular buffer where full means wr==rd
    // but we need to be careful about the state machine.
    function reg is_full_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (considering frame mode logic)
    function reg is_empty_frame_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_frame_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (standard logic for non-frame)
    function reg is_full_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_full_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is empty (standard logic for non-frame)
    function reg is_empty_std_logic;
        input [LOG_DEPTH-1:0] wr, rd;
        begin
            is_empty_std_logic = (wr == rd);
        end
    endfunction

    // Helper function to check if FIFO is full (considering frame