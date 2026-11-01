module axis_adapter #
(
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
    parameter USER_WIDTH = 1
)
(
    input  wire                     clk,
    input  wire                     rst,
    /*
     * AXI input
     */
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
    output wire [M_DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [M_KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                     m_axis_tvalid,
    input  wire                     m_axis_tready,
    output wire                     m_axis_tlast,
    output wire [ID_WIDTH-1:0]      m_axis_tid,
    output wire [DEST_WIDTH-1:0]    m_axis_tdest,
    output wire [USER_WIDTH-1:0]    m_axis_tuser
);

    // Internal state
    reg [S_DATA_WIDTH-1:0] data_buf;
    reg [S_KEEP_WIDTH-1:0] keep_buf;
    reg                    last_buf;
    reg [ID_WIDTH-1:0]     id_buf;
    reg [DEST_WIDTH-1:0]   dest_buf;
    reg [USER_WIDTH-1:0]   user_buf;
    reg                    buf_valid;

    // Output registers
    reg [M_DATA_WIDTH-1:0] m_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_tkeep_reg;
    reg                    m_tlast_reg;
    reg [ID_WIDTH-1:0]     m_tid_reg;
    reg [DEST_WIDTH-1:0]   m_tdest_reg;
    reg [USER_WIDTH-1:0]   m_tuser_reg;
    reg                    m_tvalid_reg;

    // Helper: count number of valid bytes in a keep signal
    function integer count_bytes;
        input [S_KEEP_WIDTH-1:0] keep;
        integer i;
        begin
            count_bytes = 0;
            for (i = 0; i < S_KEEP_WIDTH; i = i + 1)
                count_bytes = count_bytes + keep[i];
        end
    endfunction

    // Helper: extract byte from source data based on byte index
    // byte_index is 0-based from LSB
    function [7:0] get_byte;
        input [S_DATA_WIDTH-1:0] data;
        input [S_KEEP_WIDTH-1:0] keep;
        input integer byte_index;
        integer i;
        integer cnt;
        begin
            cnt = 0;
            for (i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                if (keep[i]) begin
                    if (cnt == byte_index)
                        get_byte = data[i*8 +: 8];
                    cnt = cnt + 1;
                end
            end
        end
    endfunction

    // Helper: build keep for output based on how many bytes are valid
    function [M_KEEP_WIDTH-1:0] build_keep;
        input integer num_bytes;
        integer i;
        begin
            for (i = 0; i < M_KEEP_WIDTH; i = i + 1)
                build_keep[i] = (i < num_bytes);
        end
    endfunction

    // Determine how many bytes are in the current buffer
    wire [S_KEEP_WIDTH-1:0] cur_keep = buf_valid ? keep_buf : s_axis_tkeep;
    wire [S_DATA_WIDTH-1:0] cur_data = buf_valid ? data_buf : s_axis_tdata;
    wire                    cur_last = buf_valid ? last_buf : s_axis_tlast;
    wire [ID_WIDTH-1:0]     cur_id   = buf_valid ? id_buf   : s_axis_tid;
    wire [DEST_WIDTH-1:0]   cur_dest = buf_valid ? dest_buf : s_axis_tdest;
    wire [USER_WIDTH-1:0]   cur_user = buf_valid ? user_buf : s_axis_tuser;

    wire integer cur_num_bytes = count_bytes(cur_keep);

    // How many bytes can be output in one beat
    wire integer out_bytes = (cur_num_bytes >= M_DATA_WIDTH/8) ? (M_DATA_WIDTH/8) : cur_num_bytes;

    // Whether we can accept new input
    wire s_ready = !buf_valid && !m_tvalid_reg;

    // Whether output is valid
    assign m_axis_tvalid = m_tvalid_reg;
    assign m_axis_tdata  = m_tdata_reg;
    assign m_axis_tkeep  = m_tkeep_reg;
    assign m_axis_tlast  = m_tlast_reg;
    assign m_axis_tid    = m_tid_reg;
    assign m_axis_tdest  = m_tdest_reg;
    assign m_axis_tuser  = m_tuser_reg;
    assign s_axis_tready = s_ready;

    // Build output data and keep
    reg [M_DATA_WIDTH-1:0] out_data;
    reg [M_KEEP_WIDTH-1:0] out_keep;
    integer i;
    integer byte_idx;

    always @(*) begin
        out_data = {M_DATA_WIDTH{1'b0}};
        out_keep = {M_KEEP_WIDTH{1'b0}};
        byte_idx = 0;
        for (i = 0; i < M_DATA_WIDTH/8; i = i + 1) begin
            if (i < out_bytes) begin
                out_data[i*8 +: 8] = get_byte(cur_data, cur_keep, byte_idx);
                out_keep[i] = 1'b1;
                byte_idx = byte_idx + 1;
            end
        end
    end

    // Whether this output beat is the last
    wire out_is_last = cur_last && (out_bytes == cur_num_bytes);

    // Whether we need to buffer remaining bytes
    wire need_buffer = cur_last ? 1'b0 : (cur_num_bytes > out_bytes);

    // Main state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_valid   <= 1'b0;
            data_buf    <= {S_DATA_WIDTH{1'b0}};
            keep_buf    <= {S_KEEP_WIDTH{1'b0}};
            last_buf    <= 1'b0;
            id_buf      <= {ID_WIDTH{1'b0}};
            dest_buf    <= {DEST_WIDTH{1'b0}};
            user_buf    <= {USER_WIDTH{1'b0}};
            m_tvalid_reg <= 1'b0;
            m_tdata_reg  <= {M_DATA_WIDTH{1'b0}};
            m_tkeep_reg  <= {M_KEEP_WIDTH{1'b0}};
            m_tlast_reg  <= 1'b0;
            m_tid_reg    <= {ID_WIDTH{1'b0}};
            m_tdest_reg  <= {DEST_WIDTH{1'b0}};
            m_tuser_reg  <= {USER_WIDTH{1'b0}};
        end else begin
            // Handle output handshake
            if (m_tvalid_reg && m_axis_tready) begin
                m_tvalid_reg <= 1'b0;
            end

            // Handle input
            if (s_axis_tvalid && s_ready) begin
                if (need_buffer) begin
                    // Buffer the remaining bytes
                    buf_valid <= 1'b1;
                    // Store remaining bytes: we output out_bytes, so remaining start at out_bytes
                    // We need to shift the data so that remaining bytes are at the start
                    // For simplicity, store the full data and keep, and track offset
                    // Actually, let's store the full beat and use a byte offset
                    // But we don't have an offset register. Let's restructure.
                    // Alternative: store the full data/keep and a byte_offset
                    // Let's add a byte_offset register
                    // For now, let's just store the full data and keep, and we'll need to track offset
                    // This is getting complex. Let's use a different approach.
                end else begin
                    // No buffering needed, just pass through
                    buf_valid <= 1'b0;
                end
            end
        end
    end

endmodule
