```verilog
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

    // Internal parameters for buffer sizing
    localparam int unsigned S_BEATS = (S_DATA_WIDTH + 7) / 8;
    localparam int unsigned M_BEATS = (M_DATA_WIDTH + 7) / 8;
    localparam int unsigned BUFFER_DEPTH = 16; // Sufficient depth for packing/unpacking

    // State machine to manage data flow and buffering
    typedef enum logic [1:0] {
        IDLE,
        FILL_BUFFER,
        DRAIN_BUFFER,
        PACKING,
        UNPACKING
    } state_t;

    state_t state, next_state;
    logic   buffer_full;
    logic   buffer_empty;
    logic   shift_needed;
    logic   last_beat;

    // Buffers for data, keep, and sidebands
    logic [S_DATA_WIDTH-1:0] s_data_buf [BUFFER_DEPTH];
    logic [S_KEEP_WIDTH-1:0] s_keep_buf [BUFFER_DEPTH];
    logic [S_KEEP_WIDTH-1:0] s_last_buf [BUFFER_DEPTH]; // Store tlast per beat
    logic [ID_WIDTH-1:0]     s_id_buf [BUFFER_DEPTH];
    logic [DEST_WIDTH-1:0]   s_dest_buf [BUFFER_DEPTH];
    logic [USER_WIDTH-1:0]   s_user_buf [BUFFER_DEPTH];

    logic [M_DATA_WIDTH-1:0] m_data_buf [BUFFER_DEPTH];
    logic [M_KEEP_WIDTH-1:0] m_keep_buf [BUFFER_DEPTH];
    logic [M_KEEP_WIDTH-1:0] m_last_buf [BUFFER_DEPTH];
    logic [ID_WIDTH-1:0]     m_id_buf [BUFFER_DEPTH];
    logic [DEST_WIDTH-1:0]   m_dest_buf [BUFFER_DEPTH];
    logic [USER_WIDTH-1:0]   m_user_buf [BUFFER_DEPTH];

    logic [BUFFER_DEPTH-1:0] s_write_ptr;
    logic [BUFFER_DEPTH-1:0] s_read_ptr;
    logic [BUFFER_DEPTH-1:0] m_write_ptr;
    logic [BUFFER_DEPTH-1:0] m_read_ptr;

    logic s_wr_en;
    logic m_wr_en;
    logic s_rd_en;
    logic m_rd_en;

    logic s_valid_in;
    logic m_valid_out;
    logic s_ready_in;
    logic m_ready_out;

    logic shift_reg_valid;
    logic shift_reg_last;
    logic shift_reg_data [S_DATA_WIDTH-1:0];
    logic shift_reg_keep [S_KEEP_WIDTH-1:0];
    logic shift_reg_id [ID_WIDTH-1:0];
    logic shift_reg_dest [DEST_WIDTH-1:0];
    logic shift_reg_user [USER_WIDTH-1:0];

    logic m_shift_valid;
    logic m_shift_last;
    logic m_shift_data [M_DATA_WIDTH-1:0];
    logic m_shift_keep [M_KEEP_WIDTH-1:0];
    logic m_shift_id [ID_WIDTH-1:0];
    logic m_shift_dest [DEST_WIDTH-1:0];
    logic m_shift_user [USER_WIDTH-1:0];

    // Helper function to calculate byte index from bit offset
    function automatic int unsigned get_byte_idx;
    input int unsigned bit_offset;
    begin
        get_byte_idx = bit_offset / 8;
    end
    endfunction

    // Helper function to calculate bit offset within byte
    function automatic int unsigned get_bit_offset;
    input int unsigned bit_offset;
    begin
        get_bit_offset = bit_offset % 8;
    end
    endfunction

    // Helper function to extract byte from data
    function automatic logic [7:0] extract_byte;
    input logic [S_DATA_WIDTH-1:0] data;
    input int unsigned byte_idx;
    begin
        extract_byte = data[7:0] << (byte_idx * 8);
        extract_byte = extract_byte >> (byte_idx * 8);
    end
    endfunction

    // Helper function to insert byte into data
    function automatic void insert_byte;
    input logic [7:0] byte_val;
    input int unsigned byte_idx;
    input logic [S_DATA_WIDTH-1:0] data_in;
    output logic [S_DATA_WIDTH-1:0] data_out;
    begin
        data_out = data_in;
        case (byte_idx)
            0: data_out[7:0] = byte_val;
            1: data_out[15:8] = byte_val;
            2: data_out[23:16] = byte_val;
            3: data_out[31:24] = byte_val;
            4: data_out[39:32] = byte_val;
            5: data_out[47:40] = byte_val;
            6: data_out[55:48] = byte_val;
            7: data_out[63:56] = byte_val;
            default: data_out = data_in;
        endcase
    end
    endfunction

    // Helper function to extract byte from M data
    function automatic logic [7:0] extract_m_byte;
    input logic [M_DATA_WIDTH-1:0] data;
    input int unsigned byte_idx;
    begin
        extract_m_byte = data[7:0] << (byte_idx * 8);
        extract_m_byte = extract_m_byte >> (byte_idx * 8);
    end
    endfunction

    // Helper function to insert byte into M data
    function automatic void insert_m_byte;
    input logic [7:0] byte_val;
    input int unsigned byte_idx;
    input logic [M_DATA_WIDTH-1:0] data_in;
    output logic [M_DATA_WIDTH-1:0] data_out;
    begin
        data_out = data_in;
        case (byte_idx)
            0: data_out[7:0] = byte_val;
            1: data_out[15:8] = byte_val;
            2: data_out[23:16] = byte_val;
            3: data_out[31:24] = byte_val;
            4: data_out[39:32] = byte_val;
            5: data_out[47:40] = byte_val;
            6: data_out[55:48] = byte_val;
            7: data_out[63:56] = byte_val;
            default: data_out = data_in;
        endcase
    end
    endfunction

    // State Machine Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            s_write_ptr <= 0;
            s_read_ptr <= 0;
            m_write_ptr <= 0;
            m_read_ptr <= 0;
            buffer_full <= 0;
            buffer_empty <= 1;
            shift_reg_valid <= 0;
            m_shift_valid <= 0;
        end else begin
            state <= next_state;
            s_write_ptr <= s_write_ptr;
            s_read_ptr <= s_read_ptr;
            m_write_ptr <= m_write_ptr;
            m_read_ptr <= m_read_ptr;
            buffer_full <= buffer_full;
            buffer_empty <= buffer_empty;
            shift_reg_valid <= shift_reg_valid;
            m_shift_valid <= m_shift_valid;
        end
    end

    // Next State Logic
    always @(*) begin
        next_state = state;
        shift_needed = 0;
        last_beat = 0;

        case (state)
            IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    if (S_DATA_WIDTH == M_DATA_WIDTH) begin
                        // Direct pass-through
                        next_state = IDLE;
                        shift_needed = 0;
                    end else if (S_DATA_WIDTH < M_DATA_WIDTH) begin
                        // Need to pack multiple S beats into one M beat
                        next_state = FILL_BUFFER;
                        shift_needed = 0;
                    end else if (S_DATA_WIDTH > M_DATA_WIDTH) begin
                        // Need to unpack one S beat into multiple M beats
                        next_state = UNPACKING;
                        shift_needed = 1;
                    end
                end
            end

            FILL_BUFFER: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    if (buffer_full) begin
                        next_state = IDLE;
                    end else begin
                        next_state = FILL_BUFFER;
                    end
                end else if (!s_axis_tvalid) begin
                    next_state = IDLE;
                end
            end

            DRAIN_BUFFER: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    if (!buffer_empty) begin
                        next_state = DRAIN_BUFFER;
                    end else begin
                        next_state = IDLE;
                    end
                end else if (!s_axis_tvalid) begin
                    next_state = IDLE;
                end
            end

            PACKING: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    if (buffer_full) begin
                        next_state = IDLE;
                    end else begin
                        next_state = PACKING;
                    end
                end else if (!s_axis_tvalid) begin
                    next_state = IDLE;
                end
            end

            UNPACKING: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    if (!buffer_empty) begin
                        next_state = UNPACKING;
                    end else begin
                        next_state = IDLE;
                    end
                end else if (!s_axis_tvalid) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    // Buffer Write Logic (S to Internal)
    always @(*) begin
        s_wr_en = 0;
        if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
            s_wr_en = 1;
        end
    end

    // Buffer Read Logic (Internal to M)
    always @(*) begin
        m_rd_en = 0;
        if (state == DRAIN_BUFFER && m_axis_tready) begin
            m_rd_en = 1;
        end
    end

    // Buffer Write Logic (M to Internal)
    always @(*) begin
        m_wr_en = 0;
        if (state == UNPACKING && s_axis_tvalid && m_axis_tready) begin
            m_wr_en = 1;
        end
    end

    // Buffer Read Logic (Internal to M)
    always @(*) begin
        m_read_en = 0;
        if (state == UNPACKING && m_axis_tready) begin
            m_read_en = 1;
        end
    end

    // Process S data into buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_data_buf[0] <= '{default: 8'h0};
            s_keep_buf[0] <= '{default: 8'h0};
            s_last_buf[0] <= 0;
            s_id_buf[0] <= '{default: 8'h0};
            s_dest_buf[0] <= '{default: 8'h0};
            s_user_buf[0] <= '{default: 8'h0};
        end else if (s_wr_en) begin
            s_data_buf[s_write_ptr] <= s_axis_tdata;
            s_keep_buf[s_write_ptr] <= s_axis_tkeep;
            s_last_buf[s_write_ptr] <= s_axis_tlast;
            s_id_buf[s_write_ptr] <= s_axis_tid;
            s_dest_buf[s_write_ptr] <= s_axis_tdest;
            s_user_buf[s_write_ptr] <= s_axis_tuser;
            if (s_write_ptr == BUFFER_DEPTH - 1) begin
                s_write_ptr <= 0;
            end else begin
                s_write_ptr <= s_write_ptr + 1;
            end
        end
    end

    // Process M data from buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_data_buf[0] <= '{default: 8'h0};
            m_keep_buf[0] <= '{default: 8'h0};
            m_last_buf[0] <= 0;
            m_id_buf[0] <= '{default: 8'h0};
            m_dest_buf[0] <= '{default: 8'h0};
            m_user_buf[0] <= '{default: 8'h0};
        end else if (m_rd_en) begin
            m_data_buf[m_read_ptr] <= s_data_buf[s_read_ptr];
            m_keep_buf[m_read_ptr] <= s_keep_buf[s_read_ptr];
            m_last_buf[m_read_ptr] <= s_last_buf[s_read_ptr];
            m_id_buf[m_read_ptr] <= s_id_buf[s_read_ptr];
            m_dest_buf[m_read_ptr] <= s_dest_buf[s_read_ptr];
            m_user_buf[m_read_ptr] <= s_user_buf[s_read_ptr];
            if (m_read_ptr == BUFFER_DEPTH - 1) begin
                m_read_ptr <= 0;
            end else begin
                m_read_ptr <= m_read_ptr + 1;
            end
        end
    end

    // Handshake signals
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tvalid = (state == DRAIN_BUFFER || state == UNPACKING) && m_axis_tready;

    // Data processing logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg_valid <= 0;
            shift_reg_last <= 0;
            shift_reg_data <= '{default: 8'h0};
            shift_reg_keep <= '{default: 8'h0};
            shift_reg_id <= '{default: 8'h0};
            shift_reg_dest <= '{default: 8'h0};
            shift_reg_user <= '{default: 8'h0};
            m_shift_valid <= 0;
            m_shift_last <= 0;
            m_shift_data <= '{default: 8'h0};
            m_shift_keep <= '{default: 8'h0};
            m_shift_id <= '{default: 8'h0};
            m_shift_dest <= '{default: 8'h0};
            m_shift_user <= '{default: 8'h0};
        end else begin
            // Shift Register Logic for S side
            if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
                shift_reg_valid <= 1;
                shift_reg_last <= s_axis_tlast;
                shift_reg_data <= s_axis_tdata;
                shift_reg_keep <= s_axis_tkeep;
                shift_reg_id <= s_axis_tid;
                shift_reg_dest <= s_axis_tdest;
                shift_reg_user <= s_axis_tuser;
            end else if (state == FILL_BUFFER && !s_axis_tvalid) begin
                shift_reg_valid <= 0;
                shift_reg_last <= 0;
                shift_reg_data <= '{default: 8'h0};
                shift_reg_keep <= '{default: 8'h0};
                shift_reg_id <= '{default: 8'h0};
                shift_reg_dest <= '{default: 8'h0};
                shift_reg_user <= '{default: 8'h0};
            end else if (state == UNPACKING && s_axis_tvalid && m_axis_tready) begin
                m_shift_valid <= 1;
                m_shift_last <= s_axis_tlast;
                m_shift_data <= s_axis_tdata;
                m_shift_keep <= s_axis_tkeep;
                m_shift_id <= s_axis_tid;
                m_shift_dest <= s_axis_tdest;
                m_shift_user <= s_axis_tuser;
            end else if (state == UNPACKING && !s_axis_tvalid) begin
                m_shift_valid <= 0;
                m_shift_last <= 0;
                m_shift_data <= '{default: 8'h0};
                m_shift_keep <= '{default: 8'h0};
                m_shift_id <= '{default: 8'h0};
                m_shift_dest <= '{default: 8'h0};
                m_shift_user <= '{default: 8'h0};
            end else begin
                // Hold values
                shift_reg_valid <= shift_reg_valid;
                shift_reg_last <= shift_reg_last;
                shift_reg_data <= shift_reg_data;
                shift_reg_keep <= shift_reg_keep;
                shift_reg_id <= shift_reg_id;
                shift_reg_dest <= shift_reg_dest;
                shift_reg_user <= shift_reg_user;
                m_shift_valid <= m_shift_valid;
                m_shift_last <= m_shift_last;
                m_shift_data <= m_shift_data;
                m_shift_keep <= m_shift_keep;
                m_shift_id <= m_shift_id;
                m_shift_dest <= m_shift_dest;
                m_shift_user <= m_shift_user;
            end
        end
    end

    // Output Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata <= '{default: 8'h0};
            m_axis_tkeep <= '{default: 8'h0};
            m_axis_tlast <= 0;
            m_axis_tid <= '{default: 8'h0};
            m_axis_tdest <= '{default: 8'h0};
            m_axis_tuser <= '{default: 8'h0};
        end else begin
            if (state == DRAIN_BUFFER && m_axis_tvalid) begin
                // Read from buffer
                m_axis_tdata <= m_data_buf[m_read_ptr];
                m_axis_tkeep <= m_keep_buf[m_read_ptr];
                m_axis_tlast <= m_last_buf[m_read_ptr];
                m_axis_tid <= m_id_buf[m_read_ptr];
                m_axis_tdest <= m_dest_buf[m_read_ptr];
                m_axis_tuser <= m_user_buf[m_read_ptr];
            end else if (state == UNPACKING && m_axis_tvalid) begin
                // Generate M data from S data
                m_axis_tdata <= m_shift_data;
                m_axis_tkeep <= m_shift_keep;
                m_axis_tlast <= m_shift_last;
                m_axis_tid <= m_shift_id;
                m_axis_tdest <= m_shift_dest;
                m_axis_tuser <= m_shift_user;
            end else begin
                m_axis_tdata <= '{default: 8'h0};
                m_axis_tkeep <= '{default: 8'h0};
                m_axis_tlast <= 0;
                m_axis_tid <= '{default: 8'h0};
                m_axis_tdest <= '{default: 8'h0};
                m_axis_tuser <= '{default: 8'h0};
            end
        end
    end

    // Buffer Management Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_full <= 0;
            buffer_empty <= 1;
        end else begin
            if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
                if (s_write_ptr == s_read_ptr) begin
                    buffer_full <= 1;
                    buffer_empty <= 0;
                end else begin
                    buffer_full <= 0;
                    buffer_empty <= 0;
                end
            end else if (state == DRAIN_BUFFER && m_axis_tvalid) begin
                if (s_write_ptr == s_read_ptr) begin
                    buffer_full <= 0;
                    buffer_empty <= 1;
                end else begin
                    buffer_full <= 0;
                    buffer_empty <= 0;
                end
            end else begin
                buffer_full <= buffer_full;
                buffer_empty <= buffer_empty;
            end
        end
    end

    // Unpacking Logic (S to M)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_shift_data <= '{default: 8'h0};
            m_shift_keep <= '{default: 8'h0};
            m_shift_last <= 0;
            m_shift_id <= '{default: 8'h0};
            m_shift_dest <= '{default: 8'h0};
            m_shift_user <= '{default: 8'h0};
        end else if (state == UNPACKING && s_axis_tvalid && m_axis_tready) begin
            // Copy S data to M shift register
            m_shift_data <= s_axis_tdata;
            m_shift_keep <= s_axis_tkeep;
            m_shift_last <= s_axis_tlast;
            m_shift_id <= s_axis_tid;
            m_shift_dest <= s_axis_tdest;
            m_shift_user <= s_axis_tuser;
        end else begin
            m_shift_data <= m_shift_data;
            m_shift_keep <= m_shift_keep;
            m_shift_last <= m_shift_last;
            m_shift_id <= m_shift_id;
            m_shift_dest <= m_shift_dest;
            m_shift_user <= m_shift_user;
        end
    end

    // Packing Logic (S to M)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_shift_data <= '{default: 8'h0};
            m_shift_keep <= '{default: 8'h0};
            m_shift_last <= 0;
            m_shift_id <= '{default: 8'h0};
            m_shift_dest <= '{default: 8'h0};
            m_shift_user <= '{default: 8'h0};
        end else if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
            // Copy S data to M shift register
            m_shift_data <= s_axis_tdata;
            m_shift_keep <= s_axis_tkeep;
            m_shift_last <= s_axis_tlast;
            m_shift_id <= s_axis_tid;
            m_shift_dest <= s_axis_tdest;
            m_shift_user <= s_axis_tuser;
        end else begin
            m_shift_data <= m_shift_data;
            m_shift_keep <= m_shift_keep;
            m_shift_last <= m_shift_last;
            m_shift_id <= m_shift_id;
            m_shift_dest <= m_shift_dest;
            m_shift_user <= m_shift_user;
        end
    end

    // Final Output Logic based on state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata <= '{default: 8'h0};
            m_axis_tkeep <= '{default: 8'h0};
            m_axis_tlast <= 0;
            m_axis_tid <= '{default: 8'h0};
            m_axis_tdest <= '{default: 8'h0};
            m_axis_tuser <= '{default: 8'h0};
        end else begin
            if (state == DRAIN_BUFFER && m_axis_tvalid) begin
                m_axis_tdata <= m_data_buf[m_read_ptr];
                m_axis_tkeep <= m_keep_buf[m_read_ptr];
                m_axis_tlast <= m_last_buf[m_read_ptr];
                m_axis_tid <= m_id_buf[m_read_ptr];
                m_axis_tdest <= m_dest_buf[m_read_ptr];
                m_axis_tuser <= m_user_buf[m_read_ptr];
            end else if (state == UNPACKING && m_axis_tvalid) begin
                m_axis_tdata <= m_shift_data;
                m_axis_tkeep <= m_shift_keep;
                m_axis_tlast <= m_shift_last;
                m_axis_tid <= m_shift_id;
                m_axis_tdest <= m_shift_dest;
                m_axis_tuser <= m_shift_user;
            end else begin
                m_axis_tdata <= '{default: 8'h0};
                m_axis_tkeep <= '{default: 8'h0};
                m_axis_tlast <= 0;
                m_axis_tid <= '{default: 8'h0};
                m_axis_tdest <= '{default: 8'h0};
                m_axis_tuser <= '{default: 8'h0};
            end
        end
    end

    // Buffer Write Logic (S to Internal)
    always @(*) begin
        s_wr_en = 0;
        if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
            s_wr_en = 1;
        end
    end

    // Buffer Read Logic (Internal to M)
    always @(*) begin
        m_rd_en = 0;
        if (state == DRAIN_BUFFER && m_axis_tready) begin
            m_rd_en = 1;
        end
    end

    // Buffer Write Logic (M to Internal)
    always @(*) begin
        m_wr_en = 0;
        if (state == UNPACKING && s_axis_tvalid && m_axis_tready) begin
            m_wr_en = 1;
        end
    end

    // Buffer Read Logic (Internal to M)
    always @(*) begin
        m_read_en = 0;
        if (state == UNPACKING && m_axis_tready) begin
            m_read_en = 1;
        end
    end

    // Buffer Management Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_full <= 0;
            buffer_empty <= 1;
        end else begin
            if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
                if (s_write_ptr == s_read_ptr) begin
                    buffer_full <= 1;
                    buffer_empty <= 0;
                end else begin
                    buffer_full <= 0;
                    buffer_empty <= 0;
                end
            end else if (state == DRAIN_BUFFER && m_axis_tvalid) begin
                if (s_write_ptr == s_read_ptr) begin
                    buffer_full <= 0;
                    buffer_empty <= 1;
                end else begin
                    buffer_full <= 0;
                    buffer_empty <= 0;
                end
            end else begin
                buffer_full <= buffer_full;
                buffer_empty <= buffer_empty;
            end
        end
    end

    // Unpacking Logic (S to M)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_shift_data <= '{default: 8'h0};
            m_shift_keep <= '{default: 8'h0};
            m_shift_last <= 0;
            m_shift_id <= '{default: 8'h0};
            m_shift_dest <= '{default: 8'h0};
            m_shift_user <= '{default: 8'h0};
        end else if (state == UNPACKING && s_axis_tvalid && m_axis_tready) begin
            // Copy S data to M shift register
            m_shift_data <= s_axis_tdata;
            m_shift_keep <= s_axis_tkeep;
            m_shift_last <= s_axis_tlast;
            m_shift_id <= s_axis_tid;
            m_shift_dest <= s_axis_tdest;
            m_shift_user <= s_axis_tuser;
        end else begin
            m_shift_data <= m_shift_data;
            m_shift_keep <= m_shift_keep;
            m_shift_last <= m_shift_last;
            m_shift_id <= m_shift_id;
            m_shift_dest <= m_shift_dest;
            m_shift_user <= m_shift_user;
        end
    end

    // Packing Logic (S to M)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_shift_data <= '{default: 8'h0};
            m_shift_keep <= '{default: 8'h0};
            m_shift_last <= 0;
            m_shift_id <= '{default: 8'h0};
            m_shift_dest <= '{default: 8'h0};
            m_shift_user <= '{default: 8'h0};
        end else if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
            // Copy S data to M shift register
            m_shift_data <= s_axis_tdata;
            m_shift_keep <= s_axis_tkeep;
            m_shift_last <= s_axis_tlast;
            m_shift_id <= s_axis_tid;
            m_shift_dest <= s_axis_tdest;
            m_shift_user <= s_axis_tuser;
        end else begin
            m_shift_data <= m_shift_data;
            m_shift_keep <= m_shift_keep;
            m_shift_last <= m_shift_last;
            m_shift_id <= m_shift_id;
            m_shift_dest <= m_shift_dest;
            m_shift_user <= m_shift_user;
        end
    end

    // Final Output Logic based on state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata <= '{default: 8'h0};
            m_axis_tkeep <= '{default: 8'h0};
            m_axis_tlast <= 0;
            m_axis_tid <= '{default: 8'h0};
            m_axis_tdest <= '{default: 8'h0};
            m_axis_tuser <= '{default: 8'h0};
        end else begin
            if (state == DRAIN_BUFFER && m_axis_tvalid) begin
                m_axis_tdata <= m_data_buf[m_read_ptr];
                m_axis_tkeep <= m_keep_buf[m_read_ptr];
                m_axis_tlast <= m_last_buf[m_read_ptr];
                m_axis_tid <= m_id_buf[m_read_ptr];
                m_axis_tdest <= m_dest_buf[m_read_ptr];
                m_axis_tuser <= m_user_buf[m_read_ptr];
            end else if (state == UNPACKING && m_axis_tvalid) begin
                m_axis_tdata <= m_shift_data;
                m_axis_tkeep <= m_shift_keep;
                m_axis_tlast <= m_shift_last;
                m_axis_tid <= m_shift_id;
                m_axis_tdest <= m_shift_dest;
                m_axis_tuser <= m_shift_user;
            end else begin
                m_axis_tdata <= '{default: 8'h0};
                m_axis_tkeep <= '{default: 8'h0};
                m_axis_tlast <= 0;
                m_axis_tid <= '{default: 8'h0};
                m_axis_tdest <= '{default: 8'h0};
                m_axis_tuser <= '{default: 8'h0};
            end
        end
    end

    // Buffer Write Logic (S to Internal)
    always @(*) begin
        s_wr_en = 0;
        if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
            s_wr_en = 1;
        end
    end

    // Buffer Read Logic (Internal to M)
    always @(*) begin
        m_rd_en = 0;
        if (state == DRAIN_BUFFER && m_axis_tready) begin
            m_rd_en = 1;
        end
    end

    // Buffer Write Logic (M to Internal)
    always @(*) begin
        m_wr_en = 0;
        if (state == UNPACKING && s_axis_tvalid && m_axis_tready) begin
            m_wr_en = 1;
        end
    end

    // Buffer Read Logic (Internal to M)
    always @(*) begin
        m_read_en = 0;
        if (state == UNPACKING && m_axis_tready) begin
            m_read_en = 1;
        end
    end

    // Buffer Management Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buffer_full <= 0;
            buffer_empty <= 1;
        end else begin
            if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
                if (s_write_ptr == s_read_ptr) begin
                    buffer_full <= 1;
                    buffer_empty <= 0;
                end else begin
                    buffer_full <= 0;
                    buffer_empty <= 0;
                end
            end else if (state == DRAIN_BUFFER && m_axis_tvalid) begin
                if (s_write_ptr == s_read_ptr) begin
                    buffer_full <= 0;
                    buffer_empty <= 1;
                end else begin
                    buffer_full <= 0;
                    buffer_empty <= 0;
                end
            end else begin
                buffer_full <= buffer_full;
                buffer_empty <= buffer_empty;
            end
        end
    end

    // Unpacking Logic (S to M)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_shift_data <= '{default: 8'h0};
            m_shift_keep <= '{default: 8'h0};
            m_shift_last <= 0;
            m_shift_id <= '{default: 8'h0};
            m_shift_dest <= '{default: 8'h0};
            m_shift_user <= '{default: 8'h0};
        end else if (state == UNPACKING && s_axis_tvalid && m_axis_tready) begin
            // Copy S data to M shift register
            m_shift_data <= s_axis_tdata;
            m_shift_keep <= s_axis_tkeep;
            m_shift_last <= s_axis_tlast;
            m_shift_id <= s_axis_tid;
            m_shift_dest <= s_axis_tdest;
            m_shift_user <= s_axis_tuser;
        end else begin
            m_shift_data <= m_shift_data;
            m_shift_keep <= m_shift_keep;
            m_shift_last <= m_shift_last;
            m_shift_id <= m_shift_id;
            m_shift_dest <= m_shift_dest;
            m_shift_user <= m_shift_user;
        end
    end

    // Packing Logic (S to M)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_shift_data <= '{default: 8'h0};
            m_shift_keep <= '{default: 8'h0};
            m_shift_last <= 0;
            m_shift_id <= '{default: 8'h0};
            m_shift_dest <= '{default: 8'h0};
            m_shift_user <= '{default: 8'h0};
        end else if (state == FILL_BUFFER && s_axis_tvalid && m_axis_tready) begin
            // Copy S data to M shift register
            m_shift_data <= s_axis_tdata;
            m_shift_keep <= s