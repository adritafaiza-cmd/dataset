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
    reg [S_DATA_WIDTH-1:0] s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0] s_axis_tkeep_reg;
    reg                    s_axis_tvalid_reg;
    reg                    s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]     s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]   s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]   s_axis_tuser_reg;

    reg [M_DATA_WIDTH-1:0] m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0] m_axis_tkeep_reg;
    reg                    m_axis_tvalid_reg;
    reg                    m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]     m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]   m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]   m_axis_tuser_reg;

    reg [S_DATA_WIDTH-1:0] data_buffer;
    reg [S_KEEP_WIDTH-1:0] keep_buffer;
    reg                    data_buffer_full;
    reg                    data_buffer_empty;
    reg [3:0]              data_buffer_count;

    reg [1:0] state;
    reg [1:0] next_state;

    // State definitions
    localparam IDLE = 2'b00;
    localparam PROCESSING = 2'b01;

    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (s_axis_tvalid && m_axis_tready) begin
                    next_state = PROCESSING;
                end
            end
            PROCESSING: begin
                if (m_axis_tready && (s_axis_tlast || data_buffer_count == 0)) begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    // AXI input register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg <= 0;
            s_axis_tkeep_reg <= 0;
            s_axis_tvalid_reg <= 0;
            s_axis_tlast_reg <= 0;
            s_axis_tid_reg <= 0;
            s_axis_tdest_reg <= 0;
            s_axis_tuser_reg <= 0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_reg <= s_axis_tdata;
            s_axis_tkeep_reg <= s_axis_tkeep;
            s_axis_tvalid_reg <= s_axis_tvalid;
            s_axis_tlast_reg <= s_axis_tlast;
            s_axis_tid_reg <= s_axis_tid;
            s_axis_tdest_reg <= s_axis_tdest;
            s_axis_tuser_reg <= s_axis_tuser;
        end
    end

    // AXI output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= 0;
            m_axis_tkeep_reg <= 0;
            m_axis_tvalid_reg <= 0;
            m_axis_tlast_reg <= 0;
            m_axis_tid_reg <= 0;
            m_axis_tdest_reg <= 0;
            m_axis_tuser_reg <= 0;
        end else if (m_axis_tready && m_axis_tvalid_reg) begin
            m_axis_tdata_reg <= m_axis_tdata;
            m_axis_tkeep_reg <= m_axis_tkeep;
            m_axis_tvalid_reg <= m_axis_tvalid;
            m_axis_tlast_reg <= m_axis_tlast;
            m_axis_tid_reg <= m_axis_tid;
            m_axis_tdest_reg <= m_axis_tdest;
            m_axis_tuser_reg <= m_axis_tuser;
        end
    end

    // Data buffer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_buffer <= 0;
            keep_buffer <= 0;
            data_buffer_full <= 0;
            data_buffer_empty <= 1;
            data_buffer_count <= 0;
        end else begin
            if (s_axis_tvalid && s_axis_tready && !s_axis_tlast) begin
                data_buffer <= s_axis_tdata;
                keep_buffer <= s_axis_tkeep;
                data_buffer_full <= 1;
                data_buffer_empty <= 0;
                data_buffer_count <= S_DATA_WIDTH / M_DATA_WIDTH;
            end else if (m_axis_tready && m_axis_tvalid_reg) begin
                if (data_buffer_count == 1) begin
                    data_buffer_full <= 0;
                    data_buffer_empty <= 1;
                    data_buffer_count <= 0;
                end else begin
                    data_buffer_count <= data_buffer_count - 1;
                end
            end
        end
    end

    // AXI input ready
    assign s_axis_tready = m_axis_tready && (state == IDLE || (state == PROCESSING && !data_buffer_full));

    // AXI output valid
    assign m_axis_tvalid = s_axis_tvalid_reg || (state == PROCESSING && !data_buffer_empty);

    // AXI output data
    assign m_axis_tdata = (state == PROCESSING && !data_buffer_empty) ? data_buffer : s_axis_tdata_reg;

    // AXI output keep
    assign m_axis_tkeep = (state == PROCESSING && !data_buffer_empty) ? keep_buffer : s_axis_tkeep_reg;

    // AXI output last
    assign m_axis_tlast = (state == PROCESSING && data_buffer_count == 1 && m_axis_tready);

    // AXI output sidebands
    assign m_axis_tid = s_axis_tid_reg;
    assign m_axis_tdest = s_axis_tdest_reg;
    assign m_axis_tuser = s_axis_tuser_reg;

endmodule
