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

    // Local parameters
    localparam S_BYTES = (S_DATA_WIDTH + 7) / 8;
    localparam M_BYTES = (M_DATA_WIDTH + 7) / 8;
    localparam MAX_BYTES = (S_BYTES > M_BYTES) ? S_BYTES : M_BYTES;
    localparam MAX_DATA_WIDTH = MAX_BYTES * 8;
    localparam S_KEEP_BITS = S_KEEP_ENABLE ? S_KEEP_WIDTH : 0;
    localparam M_KEEP_BITS = M_KEEP_ENABLE ? M_KEEP_WIDTH : 0;

    // State machine
    localparam ST_IDLE = 2'd0;
    localparam ST_PACK = 2'd1;
    localparam ST_UNPACK = 2'd2;
    localparam ST_PASS = 2'd3;

    reg [1:0] state;
    reg [MAX_DATA_WIDTH-1:0] buffer;
    reg [MAX_BYTES-1:0] keep_buffer;
    reg [7:0] byte_count;
    reg [7:0] bytes_needed;
    reg [7:0] bytes_consumed;
    reg [7:0] bytes_produced;
    reg [7:0] bytes_remaining;
    reg [7:0] s_keep_count;
    reg [7:0] m_keep_count;
    reg s_last_seen;
    reg [ID_WIDTH-1:0] id_reg;
    reg [DEST_WIDTH-1:0] dest_reg;
    reg [USER_WIDTH-1:0] user_reg;

    // Handshake signals
    wire s_handshake = s_axis_tvalid & s_axis_tready;
    wire m_handshake = m_axis_tvalid & m_axis_tready;

    // Calculate number of valid bytes in S beat
    function [7:0] count_bytes;
        input [S_KEEP_WIDTH-1:0] keep;
        integer i;
        begin
            count_bytes = 0;
            for (i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                count_bytes = count_bytes + keep[i];
            end
        end
    endfunction

    // Calculate number of valid bytes in M beat
    function [7:0] count_m_bytes;
        input [M_KEEP_WIDTH-1:0] keep;
        integer i;
        begin
            count_m_bytes = 0;
            for (i = 0; i < M_KEEP_WIDTH; i = i + 1) begin
                count_m_bytes = count_m_bytes + keep[i];
            end
        end
    endfunction

    // Helper to extract byte from buffer
    function [7:0] get_byte;
        input [MAX_DATA_WIDTH-1:0] buf;
        input [7:0] byte_idx;
        begin
            get_byte = buf[byte_idx*8 +: 8];
        end
    endfunction

    // Helper to set byte in buffer
    function [MAX_DATA_WIDTH-1:0] set_byte;
        input [MAX_DATA_WIDTH-1:0] buf;
        input [7:0] byte_idx;
        input [7:0] byte_val;
        begin
            set_byte = buf;
            set_byte[byte_idx*8 +: 8] = byte_val;
        end
    endfunction

    // Helper to extract byte from S data
    function [7:0] get_s_byte;
        input [S_DATA_WIDTH-1:0] data;
        input [7:0] byte_idx;
        begin
            get_s_byte = data[byte_idx*8 +: 8];
        end
    endfunction

    // Helper to extract byte from M data
    function [7:0] get_m_byte;
        input [M_DATA_WIDTH-1:0] data;
        input [7:0] byte_idx;
        begin
            get_m_byte = data[byte_idx*8 +: 8];
        end
    endfunction

    // Helper to set byte in M data
    function [M_DATA_WIDTH-1:0] set_m_byte;
        input [M_DATA_WIDTH-1:0] data;
        input [7:0] byte_idx;
        input [7:0] byte_val;
        begin
            set_m_byte = data;
            set_m_byte[byte_idx*8 +: 8] = byte_val;
        end
    endfunction

    // Helper to set byte in S data
    function [S_DATA_WIDTH-1:0] set_s_byte;
        input [S_DATA_WIDTH-1:0] data;
        input [7:0] byte_idx;
        input [7:0] byte_val;
        begin
            set_s_byte = data;
            set_s_byte[byte_idx*8 +: 8] = byte_val;
        end
    endfunction

    // Helper to create keep vector for M
    function [M_KEEP_WIDTH-1:0] make_m_keep;
        input [7:0] num_bytes;
        integer i;
        begin
            make_m_keep = {M_KEEP_WIDTH{1'b0}};
            for (i = 0; i < M_KEEP_WIDTH; i = i + 1) begin
                if (i < num_bytes) begin
                    make_m_keep[i] = 1'b1;
                end
            end
        end
    endfunction

    // Helper to create keep vector for S
    function [S_KEEP_WIDTH-1:0] make_s_keep;
        input [7:0] num_bytes;
        integer i;
        begin
            make_s_keep = {S_KEEP_WIDTH{1'b0}};
            for (i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                if (i < num_bytes) begin
                    make_s_keep[i] = 1'b1;
                end
            end
        end
    endfunction

    // Determine if we need to pack or unpack
    wire need_pack = (S_BYTES > M_BYTES);
    wire need_unpack = (S_BYTES < M_BYTES);
    wire same_width = (S_BYTES == M_BYTES);

    // State machine logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            buffer <= {MAX_DATA_WIDTH{1'b0}};
            keep_buffer <= {MAX_BYTES{1'b0}};
            byte_count <= 8'd0;
            bytes_needed <= 8'd0;
            bytes_consumed <= 8'd0;
            bytes_produced <= 8'd0;
            bytes_remaining <= 8'd0;
            s_keep_count <= 8'd0;
            m_keep_count <= 8'd0;
            s_last_seen <= 1'b0;
            id_reg <= {ID_WIDTH{1'b0}};
            dest_reg <= {DEST_WIDTH{1'b0}};
            user_reg <= {USER_WIDTH{1'b0}};
        end else begin
            case (state)
                ST_IDLE: begin
                    if (s_axis_tvalid) begin
                        if (same_width) begin
                            state <= ST_PASS;
                            s_last_seen <= s_axis_tlast;
                            id_reg <= s_axis_tid;
                            dest_reg <= s_axis_tdest;
                            user_reg <= s_axis_tuser;
                        end else if (need_pack) begin
                            state <= ST_PACK;
                            buffer <= {MAX_DATA_WIDTH{1'b0}};
                            keep_buffer <= {MAX_BYTES{1'b0}};
                            byte_count <= 8'd0;
                            bytes_needed <= 8'd0;
                            bytes_consumed <= 8'd0;
                            bytes_produced <= 8'd0;
                            bytes_remaining <= 8'd0;
                            s_keep_count <= 8'd0;
                            m_keep_count <= 8'd0;
                            s_last_seen <= 1'b0;
                            id_reg <= s_axis_tid;
                            dest_reg <= s_axis_tdest;
                            user_reg <= s_axis_tuser;
                        end else begin
                            state <= ST_UNPACK;
                            buffer <= {MAX_DATA_WIDTH{1'b0}};
                            keep_buffer <= {MAX_BYTES{1'b0}};
                            byte_count <= 8'd0;
                            bytes_needed <= 8'd0;
                            bytes_consumed <= 8'd0;
                            bytes_produced <= 8'd0;
                            bytes_remaining <= 8'd0;
                            s_keep_count <= 8'd0;
                            m_keep_count <= 8'd0;
                            s_last_seen <= 1'b0;
                            id_reg <= s_axis_tid;
                            dest_reg <= s_axis_tdest;
                            user_reg <= s_axis_tuser;
                        end
                    end
                end

                ST_PASS: begin
                    if (s_handshake) begin
                        if (s_axis_tlast) begin
                            state <= ST_IDLE;
                        end else begin
                            id_reg <= s_axis_tid;
                            dest_reg <= s_axis_tdest;
                            user_reg <= s_axis_tuser;
                        end
                    end
                end

                ST_PACK: begin
                    // Accumulate bytes from S into buffer
                    if (s_handshake) begin
                        // Add bytes from current S beat to buffer
                        begin : pack_add
                            integer i;
                            reg [MAX_DATA_WIDTH-1:0] new_buffer;
                            reg [MAX_BYTES-1:0] new_keep;
                            reg [7:0] new_byte_count;
                            reg [7:0] s_bytes;
                            reg [7:0] m_bytes;
                            reg [7:0] total_bytes;
                            reg [7:0] bytes_to_produce;
                            reg [7:0] bytes_to_consume;
                            reg [7:0] remaining_after;
                            reg [7:0] s_keep_cnt;
                            reg [7:0] m_keep_cnt;
                            reg [7:0] byte_idx;
                            reg [7:0] s_byte_idx;
                            reg [7:0] m_byte_idx;
                            reg [7:0] buf_byte_idx;
                            reg [7:0] s_byte_val;
                            reg [7:0] m_byte_val;
                            reg [7:0] buf_byte_val;
                            reg [7:0] new_bytes_needed;
                            reg [7:0] new_bytes_consumed;
                            reg [7:0] new_bytes_produced;
                            reg [7:0] new_bytes_remaining;
                            reg [7:0] new_s_keep_count;
                            reg [7:0] new_m_keep_count;
                            reg new_s_last_seen;
                            reg [ID_WIDTH-1:0] new_id_reg;
                            reg [DEST_WIDTH-1:0] new_dest_reg;
                            reg [USER_WIDTH-1:0] new_user_reg;
                            reg new_state;
                        begin
                            s_bytes = count_bytes(s_axis_tkeep);
                            m_bytes = M_BYTES;
                            total_bytes = byte_count + s_bytes;
                            
                            // Determine how many M beats we can produce
                            bytes_to_produce = total_bytes / m_bytes;
                            if (bytes_to_produce > 0) begin
                                bytes_to_produce = m_bytes; // We'll produce one M beat at a time
                            end else begin
                                bytes_to_produce = 0;
                            end
                            
                            // Actually, let's think differently. We accumulate until we have enough for one M beat.
                            // bytes_needed = M_BYTES
                            // When byte_count >= M_BYTES, we can produce one M beat.
                            
                            new_buffer = buffer;
                            new_keep = keep_buffer;
                            new_byte_count = byte_count;
                            
                            // Add bytes from S beat to buffer
                            s_keep_cnt = count_bytes(s_axis_tkeep);
                            for (i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                                if (s_axis_tkeep[i]) begin
                                    s_byte_idx = i;
                                    s_byte_val = get_s_byte(s_axis_tdata, s_byte_idx);
                                    buf_byte_idx = new_byte_count;
                                    new_buffer = set_byte(new_buffer, buf_byte_idx, s_byte_val);
                                    new_keep[buf_byte_idx] = 1'b1;
                                    new_byte_count = new_byte_count + 1;
                                end
                            end
                            
                            // Check if we have enough bytes for an M beat
                            if (new_byte_count >= M_BYTES) begin
                                // Produce one M beat
                                m_keep_cnt = M_BYTES;
                                for (i = 0; i < M_BYTES; i = i + 1) begin
                                    buf_byte_idx = i;
                                    m_byte_val = get_byte(new_buffer, buf_byte_idx);
                                    // We'll output this in combinational logic
                                end
                                
                                // Shift buffer to remove consumed bytes
                                for (i = M_BYTES; i < new_byte_count; i = i + 1) begin
                                    buf_byte_idx = i - M_BYTES;
                                    buf_byte_val = get_byte(new_buffer, i);
                                    new_buffer = set_byte(new_buffer, buf_byte_idx, buf_byte_val);
                                    new_keep[buf_byte_idx] = new_keep[i];
                                end
                                for (i = 0; i < M_BYTES; i = i + 1) begin
                                    new_keep[i] = 1'b0;
                                end
                                new_byte_count = new_byte_count - M_BYTES;
                                
                                // Update state
                                new_state = ST_PACK;
                                new_s_last_seen = s_last_seen;
                                new_id_reg = id_reg;
                                new_dest_reg = dest_reg;
                                new_user_reg = user_reg;
                                new_bytes_needed = 0;
                                new_bytes_consumed = 0;
                                new_bytes_produced = 0;
                                new_bytes_remaining = 0;
                                new_s_keep_count = 0;
                                new_m_keep_count = 0;
                                
                                if (s_axis_tlast) begin
                                    new_s_last_seen = 1'b1;
                                    // If this is the last S beat, we need to handle remaining bytes
                                    if (new_byte_count == 0) begin
                                        new_state = ST_IDLE;
                                    end
                                end
                            end else begin
                                new_state = ST_PACK;
                                new_s_last_seen = s_last_seen;
                                new_id_reg = s_axis_tid;
                                new_dest_reg = s_axis_tdest;
                                new_user_reg = s_axis_tuser;
                                new_bytes_needed = 0;
                                new_bytes_consumed = 0;
                                new_bytes_produced = 0;
                                new_bytes_remaining = 0;
                                new_s_keep_count = 0;
                                new_m_keep_count = 0;
                                
                                if (s_axis_tlast) begin
                                    new_s_last_seen = 1'b1;
                                end
                            end
                            
                            buffer <= new_buffer;
                            keep_buffer <= new_keep;
                            byte_count <= new_byte_count;
                            bytes_needed <= new_bytes_needed;
                            bytes_consumed <= new_bytes_consumed;
                            bytes_produced <= new_bytes_produced;
                            bytes_remaining <= new_bytes_remaining;
                            s_keep_count <= new_s_keep_count;
                            m_keep_count <= new_m_keep_count;
                            s_last_seen <= new_s_last_seen;
                            id_reg <= new_id_reg;
                            dest_reg <= new_dest_reg;
                            user_reg <= new_user_reg;
                            state <= new_state;
                        end
                    end
                end

                ST_UNPACK: begin
                    // Accumulate bytes from S into buffer, then unpack into M beats
                    if (s_handshake) begin
                        begin : unpack_add
                            integer i;
                            reg [MAX_DATA_WIDTH-1:0] new_buffer;
                            reg [MAX_BYTES-1:0] new_keep;
                            reg [7:0] new_byte_count;
                            reg [7:0] s_bytes;
                            reg [7:0] m_bytes;
                            reg [7:0] total_bytes;
                            reg [7:0] bytes_to_produce;
                            reg [7:0] s_keep_cnt;
                            reg [7:0] m_keep_cnt;
                            reg [7:0] byte_idx;
                            reg [7:0] s_byte_idx;
                            reg [7:0] m_byte_idx;
                            reg [7:0] buf_byte_idx;
                            reg [7:0] s_byte_val;
                            reg [7:0] m_byte_val;
                            reg [7:0] buf_byte_val;
                            reg [7:0] new_bytes_needed;
                            reg [7:0] new_bytes_consumed;
                            reg [7:0] new_bytes_produced;
                            reg [7:0] new_bytes_remaining;
                            reg [7:0] new_s_keep_count;
                            reg [7:0] new_m_keep_count;
                            reg new_s_last_seen;
                            reg [ID_WIDTH-1:0] new_id_reg;
                            reg [DEST_WIDTH-1:0] new_dest_reg;
                            reg [USER_WIDTH-1:0] new_user_reg;
                            reg new_state;
                        begin
                            s_bytes = count_bytes(s_axis_tkeep);
                            m_bytes = M_BYTES;
                            total_bytes = byte_count + s_bytes;
                            
                            new_buffer = buffer;
                            new_keep = keep_buffer;
                            new_byte_count = byte_count;
                            
                            // Add bytes from S beat to buffer
                            s_keep_cnt = count_bytes(s_axis_tkeep);
                            for (i = 0; i < S_KEEP_WIDTH; i = i + 1) begin
                                if (s_axis_tkeep[i]) begin
                                    s_byte_idx = i;
                                    s_byte_val = get_s_byte(s_axis_tdata, s_byte_idx);
                                    buf_byte_idx = new_byte_count;
                                    new_buffer = set_byte(new_buffer, buf_byte_idx, s_byte_val);
                                    new_keep[buf_byte_idx] = 1'b1;
                                    new_byte_count = new_byte_count + 1;
                                end
                            end
                            
                            // Check if we have enough bytes for an M beat
                            if (new_byte_count >= M_BYTES) begin
                                // Produce one M beat
                                m_keep_cnt = M_BYTES;
                                for (i = 0; i < M_BYTES; i = i + 1) begin
                                    buf_byte_idx = i;
                                    m_byte_val = get_byte(new_buffer, buf_byte_idx);
                                    // We'll output this in combinational logic
                                end
                                
                                // Shift buffer to remove consumed bytes
                                for (i = M_BYTES; i < new_byte_count; i = i + 1) begin
                                    buf_byte_idx = i - M_BYTES;
                                    buf_byte_val = get_byte(new_buffer, i);
                                    new_buffer = set_byte(new_buffer, buf_byte_idx, buf_byte_val);
                                    new_keep[buf_byte_idx] = new_keep[i];
                                end
                                for (i = 0; i < M_BYTES; i = i + 1) begin
                                    new_keep[i] = 1'b0;
                                end
                                new_byte_count = new_byte_count - M_BYTES;
                                
                                // Update state
                                new_state = ST_UNPACK;
                                new_s_last_seen = s_last_seen;
                                new_id_reg = id_reg;
                                new_dest_reg = dest_reg;
                                new_user_reg = user_reg;
                                new_bytes_needed = 0;
                                new_bytes_consumed = 0;
                                new_bytes_produced = 0;
                                new_bytes_remaining = 0;
                                new_s_keep_count = 0;
                                new_m_keep_count = 0;
                                
                                if (s_axis_tlast) begin
                                    new_s_last_seen = 1'b1;
                                    // If this is the last S beat, we need to handle remaining bytes
                                    if (new_byte_count == 0) begin
                                        new_state = ST_IDLE;
                                    end
                                end
                            end else begin
                                new_state = ST_UNPACK;
                                new_s_last_seen = s_last_seen;
                                new_id_reg = s_axis_tid;
                                new_dest_reg = s_axis_tdest;
                                new_user_reg = s_axis_tuser;
                                new_bytes_needed = 0;
                                new_bytes_consumed = 0;
                                new_bytes_produced = 0;
                                new_bytes_remaining = 0;
                                new_s_keep_count = 0;
                                new_m_keep_count = 0;
                                
                                if (s_axis_tlast) begin
                                    new_s_last_seen = 1'b1;
                                end
                            end
                            
                            buffer <= new_buffer;
                            keep_buffer <= new_keep;
                            byte_count <= new_byte_count;
                            bytes_needed <= new_bytes_needed;
                            bytes_consumed <= new_bytes_consumed;
                            bytes_produced <= new_bytes_produced;
                            bytes_remaining <= new_bytes_remaining;
                            s_keep_count <= new_s_keep_count;
                            m_keep_count <= new_m_keep_count;
                            s_last_seen <= new_s_last_seen;
                            id_reg <= new_id_reg;
                            dest_reg <= new_dest_reg;
                            user_reg <= new_user_reg;
                            state <= new_state;
                        end
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

    // Combinational logic for outputs
    // s_axis_tready
    assign s_axis_tready = (state == ST_IDLE) || (state == ST_PASS) || 
                           ((state == ST_PACK) || (state == ST_UNPACK));

    // m_axis_tvalid
    wire m_valid_comb;
    assign m_valid_comb = (state == ST_PASS) ? s_axis_tvalid :
                          ((state == ST_PACK) || (state == ST_UNPACK)) ? (byte_count >= M_BYTES) : 1'b0;
    assign m_axis_tvalid = m_valid_comb;

    // m_axis_tdata
    reg [M_DATA_WIDTH-1:0] m_data_comb;
    integer i;
    always @* begin
        m_data_comb = {M_DATA_WIDTH{1'b0}};
        if (state == ST_PASS) begin
            m_data_comb = s_axis_tdata;
        end else if ((state == ST_PACK) || (state == ST_UNPACK)) begin
            for (i = 0; i < M_BYTES; i = i + 1) begin
                m_data_comb[i*8 +: 8] = get_byte(buffer, i);
            end
        end
    end
    assign m_axis_tdata = m_data_comb;

    // m_axis_tkeep
    reg [M_KEEP_WIDTH-1:0] m_keep_comb;
    always @* begin
        m_keep_comb = {M_KEEP_WIDTH{1'b0}};
        if (state == ST_PASS) begin
            if (M_KEEP_ENABLE) begin
                m_keep_comb = s_axis_tkeep;
            end else begin
                m_keep_comb = {M_KEEP_WIDTH{1'b1}};
            end
        end else if ((state == ST_PACK) || (state == ST_UNPACK)) begin
            if (M_KEEP_ENABLE) begin
                for (i = 0; i < M_KEEP_WIDTH; i = i + 1) begin
                    if (i < M_BYTES) begin
                        m_keep_comb[i] = 1'b1;
                    end else begin
                        m_keep_comb[i] = 1'b0;
                    end
                end
            end else begin
                m_keep_comb = {M_KEEP_WIDTH{1'b1}};
            end
        end
    end
    assign m_axis_tkeep = m_keep_comb;

    // m_axis_tlast
    reg m_last_comb;
    always @* begin
        m_last_comb = 1'b0;
        if (state == ST_PASS) begin
            m_last_comb = s_axis_tlast;
        end else if ((state == ST_PACK) || (state == ST_UNPACK)) begin
            if (s_last_seen && (byte_count == M_BYTES)) begin
                m_last_comb = 1'b1;
            end
        end
    end
    assign m_axis_tlast = m_last_comb;

    // m_axis_tid
    assign m_axis_tid = (state == ST_PASS) ? s_axis_tid : id_reg;

    // m_axis_tdest
    assign m_axis_tdest = (state == ST_PASS) ? s_axis_tdest : dest_reg;

    // m_axis_tuser
    assign m_axis_tuser = (state == ST_PASS) ? s_axis_tuser : user_reg;

endmodule
