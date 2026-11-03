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
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_int;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_int;
    reg                             m_axis_tlast_int;
    reg [ID_WIDTH-1:0]              m_axis_tid_int;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_int;
    reg [USER_WIDTH-1:0]            m_axis_tuser_int;
    reg [S_DATA_WIDTH-1:0]          data_buffer;
    reg [S_KEEP_WIDTH-1:0]          keep_buffer;
    reg                             data_buffer_valid;
    reg                             data_buffer_last;
    reg [ID_WIDTH-1:0]              data_buffer_tid;
    reg [DEST_WIDTH-1:0]            data_buffer_tdest;
    reg [USER_WIDTH-1:0]            data_buffer_tuser;
    reg [7:0]                       buffer_pointer;
    reg [7:0]                       bits_in_buffer;
    reg [7:0]                       bits_to_send;
    reg [M_DATA_WIDTH-1:0]          data_out;
    reg [M_KEEP_WIDTH-1:0]          keep_out;
    reg [1:0]                       state;

    // State definitions
    localparam IDLE = 2'b00;
    localparam BUFFERING = 2'b01;
    localparam SENDING = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tready_int <= 1'b0;
            m_axis_tvalid_int <= 1'b0;
            m_axis_tdata_int <= {M_DATA_WIDTH{1'b0}};
            m_axis_tkeep_int <= {M_KEEP_WIDTH{1'b0}};
            m_axis_tlast_int <= 1'b0;
            m_axis_tid_int <= {ID_WIDTH{1'b0}};
            m_axis_tdest_int <= {DEST_WIDTH{1'b0}};
            m_axis_tuser_int <= {USER_WIDTH{1'b0}};
            data_buffer <= {S_DATA_WIDTH{1'b0}};
            keep_buffer <= {S_KEEP_WIDTH{1'b0}};
            data_buffer_valid <= 1'b0;
            data_buffer_last <= 1'b0;
            data_buffer_tid <= {ID_WIDTH{1'b0}};
            data_buffer_tdest <= {DEST_WIDTH{1'b0}};
            data_buffer_tuser <= {USER_WIDTH{1'b0}};
            buffer_pointer <= 8'b0;
            bits_in_buffer <= 8'b0;
            bits_to_send <= 8'b0;
            data_out <= {M_DATA_WIDTH{1'b0}};
            keep_out <= {M_KEEP_WIDTH{1'b0}};
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    s_axis_tready_int <= 1'b1;
                    m_axis_tvalid_int <= 1'b0;
                    if (s_axis_tvalid) begin
                        data_buffer <= s_axis_tdata;
                        keep_buffer <= s_axis_tkeep;
                        data_buffer_valid <= 1'b1;
                        data_buffer_last <= s_axis_tlast;
                        data_buffer_tid <= s_axis_tid;
                        data_buffer_tdest <= s_axis_tdest;
                        data_buffer_tuser <= s_axis_tuser;
                        buffer_pointer <= 8'b0;
                        bits_in_buffer <= S_DATA_WIDTH;
                        bits_to_send <= M_DATA_WIDTH;
                        state <= BUFFERING;
                    end
                end
                BUFFERING: begin
                    if (bits_in_buffer >= bits_to_send) begin
                        data_out <= data_buffer >> buffer_pointer;
                        keep_out <= keep_buffer >> (buffer_pointer / 8);
                        m_axis_tvalid_int <= 1'b1;
                        m_axis_tlast_int <= data_buffer_last && (bits_in_buffer == bits_to_send);
                        m_axis_tid_int <= data_buffer_tid;
                        m_axis_tdest_int <= data_buffer_tdest;
                        m_axis_tuser_int <= data_buffer_tuser;
                        if (m_axis_tready) begin
                            buffer_pointer <= buffer_pointer + bits_to_send;
                            bits_in_buffer <= bits_in_buffer - bits_to_send;
                            bits_to_send <= M_DATA_WIDTH;
                            if (bits_in_buffer == 0) begin
                                s_axis_tready_int <= 1'b1;
                                state <= IDLE;
                            end else begin
                                state <= SENDING;
                            end
                        end
                    end else begin
                        bits_to_send <= bits_to_send - bits_in_buffer;
                        data_out <= {data_buffer >> buffer_pointer, data_out[M_DATA_WIDTH-bits_in_buffer-1:0]};
                        keep_out <= {keep_buffer >> (buffer_pointer / 8), keep_out[M_KEEP_WIDTH-(buffer_pointer / 8)-1:0]};
                        m_axis_tvalid_int <= 1'b1;
                        m_axis_tlast_int <= 1'b0;
                        m_axis_tid_int <= data_buffer_tid;
                        m_axis_tdest_int <= data_buffer_tdest;
                        m_axis_tuser_int <= data_buffer_tuser;
                        if (m_axis_tready) begin
                            buffer_pointer <= 0;
                            bits_in_buffer <= 0;
                            state <= IDLE;
                        end
                    end
                end
                SENDING: begin
                    if (bits_in_buffer >= bits_to_send) begin
                        data_out <= data_buffer >> buffer_pointer;
                        keep_out <= keep_buffer >> (buffer_pointer / 8);
                        m_axis_tvalid_int <= 1'b1;
                        m_axis_tlast_int <= data_buffer_last && (bits_in_buffer == bits_to_send);
                        m_axis_tid_int <= data_buffer_tid;
                        m_axis_tdest_int <= data_buffer_tdest;
                        m_axis_tuser_int <= data_buffer_tuser;
                        if (m_axis_tready) begin
                            buffer_pointer <= buffer_pointer + bits_to_send;
                            bits_in_buffer <= bits_in_buffer - bits_to_send;
                            bits_to_send <= M_DATA_WIDTH;
                            if (bits_in_buffer == 0) begin
                                state <= IDLE;
                            end else begin
                                state <= SENDING;
                            end
                        end
                    end else begin
                        bits_to_send <= bits_to_send - bits_in_buffer;
                        data_out <= {data_buffer >> buffer_pointer, data_out[M_DATA_WIDTH-bits_in_buffer-1:0]};
                        keep_out <= {keep_buffer >> (buffer_pointer / 8), keep_out[M_KEEP_WIDTH-(buffer_pointer / 8)-1:0]};
                        m_axis_tvalid_int <= 1'b1;
                        m_axis_tlast_int <= 1'b0;
                        m_axis_tid_int <= data_buffer_tid;
                        m_axis_tdest_int <= data_buffer_tdest;
                        m_axis_tuser_int <= data_buffer_tuser;
                        if (m_axis_tready) begin
                            buffer_pointer <= 0;
                            bits_in_buffer <= 0;
                            state <= IDLE;
                        end
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    // Assign outputs
    assign s_axis_tready = s_axis_tready_int;
    assign m_axis_tdata = m_axis_tdata_int;
    assign m_axis_tkeep = m_axis_tkeep_int;
    assign m_axis_tvalid = m_axis_tvalid_int;
    assign m_axis_tlast = m_axis_tlast_int;
    assign m_axis_tid = m_axis_tid_int;
    assign m_axis_tdest = m_axis_tdest_int;
    assign m_axis_tuser = m_axis_tuser_int;

endmodule
