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

    // Internal signals
    reg                             s_axis_tready_int;
    reg                             m_axis_tvalid_int;
    reg [S_DATA_WIDTH-1:0]          buffer;
    reg                             buffer_valid;
    reg                             buffer_last;
    reg [S_KEEP_WIDTH-1:0]          buffer_keep;
    reg [ID_WIDTH-1:0]              buffer_id;
    reg [DEST_WIDTH-1:0]            buffer_dest;
    reg [USER_WIDTH-1:0]            buffer_user;
    reg [$clog2(M_DATA_WIDTH/S_DATA_WIDTH)-1:0] buffer_ptr;
    reg [$clog2(M_DATA_WIDTH/S_DATA_WIDTH)-1:0] output_ptr;
    reg [M_DATA_WIDTH-1:0]          output_data;
    reg [M_KEEP_WIDTH-1:0]          output_keep;
    reg                             output_last;
    reg [ID_WIDTH-1:0]              output_id;
    reg [DEST_WIDTH-1:0]            output_dest;
    reg [USER_WIDTH-1:0]            output_user;

    // Reset and initialization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_int <= 0;
            m_axis_tvalid_int <= 0;
            buffer_valid      <= 0;
            buffer_last       <= 0;
            buffer_ptr        <= 0;
            output_ptr        <= 0;
            output_last       <= 0;
        end else begin
            // Accept input data
            if (s_axis_tvalid && s_axis_tready_int) begin
                buffer        <= s_axis_tdata;
                buffer_keep   <= s_axis_tkeep;
                buffer_last   <= s_axis_tlast;
                buffer_id     <= s_axis_tid;
                buffer_dest   <= s_axis_tdest;
                buffer_user   <= s_axis_tuser;
                buffer_valid  <= 1;
                buffer_ptr    <= 0;
            end

            // Packing data into output
            if (buffer_valid) begin
                case (buffer_ptr)
                    0: begin
                        output_data[M_DATA_WIDTH-1:S_DATA_WIDTH-1] <= buffer;
                        output_keep[M_KEEP_WIDTH-1:1] <= buffer_keep >> 1;
                    end
                    default: begin
                        output_data[buffer_ptr*S_DATA_WIDTH-1:(buffer_ptr-1)*S_DATA_WIDTH] <= buffer;
                        output_keep[buffer_ptr] <= buffer_keep[0];
                    end
                endcase
                buffer_ptr <= buffer_ptr + 1;

                if (buffer_ptr == M_DATA_WIDTH/S_DATA_WIDTH - 1) begin
                    output_last <= buffer_last;
                    output_id   <= buffer_id;
                    output_dest <= buffer_dest;
                    output_user <= buffer_user;
                    buffer_valid <= 0;
                    output_ptr   <= 0;
                    m_axis_tvalid_int <= 1;
                end
            end

            // Sending packed data
            if (m_axis_tready && m_axis_tvalid_int) begin
                m_axis_tvalid_int <= 0;
            end

            // Control s_axis_tready_int
            s_axis_tready_int <= ~buffer_valid || (buffer_valid && buffer_ptr == M_DATA_WIDTH/S_DATA_WIDTH - 1);
        end
    end

    // Assign outputs
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tdata  = output_data;
    assign m_axis_tkeep  = output_keep;
    assign m_axis_tlast  = output_last;
    assign m_axis_tid    = output_id;
    assign m_axis_tdest  = output_dest;
    assign m_axis_tuser  = output_user;

endmodule
