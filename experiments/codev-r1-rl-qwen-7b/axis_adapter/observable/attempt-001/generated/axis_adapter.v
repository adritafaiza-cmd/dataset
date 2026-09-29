module axis_adapter #(
    parameter S_DATA_WIDTH = 8,
    parameter S_KEEP_ENABLE = (S_DATA_WIDTH > 8),
    parameter S_KEEP_WIDTH = ((S_DATA_WIDTH + 7) / 8),
    parameter M_DATA_WIDTH = 8,
    parameter M_KEEP_ENABLE = (M_DATA_WIDTH > 8),
    parameter M_KEEP_WIDTH = ((M_DATA_WIDTH + 7) / 8),
    parameter ID_ENABLE = 0,
    parameter ID_WIDTH = 8,
    parameter DEST_ENABLE = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1
) (
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

    localparam S_BYTES = (S_DATA_WIDTH + 7) / 8;
    localparam M_BYTES = (M_DATA_WIDTH + 7) / 8;
    localparam MAX_BYTES = (S_BYTES > M_BYTES) ? S_BYTES : M_BYTES;

    reg [MAX_BYTES*8-1:0] buffer;
    reg [MAX_BYTES*8-1:0] buffer_keep;
    reg [31:0] buffer_count;
    reg [ID_WIDTH-1:0] id_reg;
    reg [DEST_WIDTH-1:0] dest_reg;
    reg [USER_WIDTH-1:0] user_reg;
    reg tlast_reg;

    // Input handling
    reg [S_DATA_WIDTH-1:0] input_data;
    reg [S_KEEP_WIDTH-1:0] input_keep;
    reg input_tlast;
    reg [ID_WIDTH-1:0] input_id;
    reg [DEST_WIDTH-1:0] input_dest;
    reg [USER_WIDTH-1:0] input_user;
    reg input_valid;

    // Output handling
    reg [M_DATA_WIDTH-1:0] output_data;
    reg [M_KEEP_WIDTH-1:0] output_keep;
    reg output_tlast;
    reg [ID_WIDTH-1:0] output_id;
    reg [DEST_WIDTH-1:0] output_dest;
    reg [USER_WIDTH-1:0] output_user;
    reg output_valid;

    // Split count for S_BYTES > M_BYTES
    localparam S_BYTES_PER_M = S_BYTES / M_BYTES;
    reg [31:0] split_count;

    // Input ready signal
    assign s_axis_tready = (S_BYTES > M_BYTES) ? (split_count < S_BYTES_PER_M) : 
                          (buffer_count + S_BYTES <= MAX_BYTES);

    // Output assignments
    assign m_axis_tvalid = output_valid;
    assign m_axis_tdata = output_data;
    assign m_axis_tkeep = output_keep;
    assign m_axis_tlast = output_tlast;
    assign m_axis_tid = output_id;
    assign m_axis_tdest = output_dest;
    assign m_axis_tuser = output_user;

    // Main logic
    always @(posedge clk) begin
        if (rst) begin
            buffer_count <= 0;
            buffer <= 0;
            buffer_keep <= 0;
            split_count <= 0;
            input_valid <= 0;
            output_valid <= 0;
            // Reset other registers
        end else begin
            // Handle input
            if (s_axis_tvalid && s_axis_tready) begin
                if (S_BYTES > M_BYTES) begin
                    // Split into multiple outputs
                    input_data <= s_axis_tdata;
                    input_keep <= s_axis_tkeep;
                    input_tlast <= s_axis_tlast;
                    input_id <= s_axis_tid;
                    input_dest <= s_axis_tdest;
                    input_user <= s_axis_tuser;
                    split_count <= 0;
                end else begin
                    // Accumulate
                    buffer[buffer_count*8 +: S_DATA_WIDTH] <= s_axis_tdata;
                    buffer_keep[buffer_count*8/S_KEEP_WIDTH +: S_KEEP_WIDTH] <= s_axis_tkeep;
                    buffer_count <= buffer_count + S_BYTES;
                    if (ID_ENABLE) id_reg <= s_axis_tid;
                    if (DEST_ENABLE) dest_reg <= s_axis_tdest;
                    if (USER_ENABLE) user_reg <= s_axis_tuser;
                    tlast_reg <= s_axis_tlast;
                end
            end

            // Handle output
            if (m_axis_tready) begin
                if (output_valid) begin
                    output_valid <= 0;
                    if (S_BYTES > M_BYTES) begin
                        // Move to next split
                        split_count <= split_count + 1;
                    end else begin
                        // Subtract M_BYTES from buffer
                        buffer_count <= buffer_count - M_BYTES;
                    end
                end
            end

            // Generate outputs
            if (S_BYTES > M_BYTES) begin
                if (split_count < S_BYTES_PER_M && input_valid) begin
                    output_data <= input_data[split_count*M_DATA_WIDTH +: M_DATA_WIDTH];
                    output_keep <= input_keep[split_count*M_KEEP_WIDTH +: M_KEEP_WIDTH];
                    output_tlast <= (split_count == S_BYTES_PER_M -1) ? input_tlast : 0;
                    output_id <= input_id;
                    output_dest <= input_dest;
                    output_user <= input_user;
                    output_valid <= 1;
                end
            end else begin
                if (buffer_count >= M_BYTES) begin
                    output_data <= buffer[(buffer_count - M_BYTES)*8 +: M_DATA_WIDTH];
                    output_keep <= buffer_keep[(buffer_count - M_BYTES)*8/S_KEEP_WIDTH +: M_KEEP_WIDTH];
                    output_tlast <= tlast_reg;
                    output_id <= id_reg;
                    output_dest <= dest_reg;
                    output_user <= user_reg;
                    output_valid <= 1;
                end
            end
        end
    end

endmodule
