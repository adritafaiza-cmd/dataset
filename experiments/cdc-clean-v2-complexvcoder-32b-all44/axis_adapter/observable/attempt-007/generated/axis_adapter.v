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
    reg [S_DATA_WIDTH-1:0]          s_axis_tdata_reg;
    reg [S_KEEP_WIDTH-1:0]          s_axis_tkeep_reg;
    reg                             s_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              s_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            s_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            s_axis_tuser_reg;
    reg [M_DATA_WIDTH-1:0]          m_axis_tdata_reg;
    reg [M_KEEP_WIDTH-1:0]          m_axis_tkeep_reg;
    reg                             m_axis_tvalid_reg;
    reg                             m_axis_tlast_reg;
    reg [ID_WIDTH-1:0]              m_axis_tid_reg;
    reg [DEST_WIDTH-1:0]            m_axis_tdest_reg;
    reg [USER_WIDTH-1:0]            m_axis_tuser_reg;
    reg [S_DATA_WIDTH-1:0]          data_fifo [0:255];
    reg [S_KEEP_WIDTH-1:0]          keep_fifo [0:255];
    reg                             last_fifo [0:255];
    reg [ID_WIDTH-1:0]              id_fifo [0:255];
    reg [DEST_WIDTH-1:0]            dest_fifo [0:255];
    reg [USER_WIDTH-1:0]            user_fifo [0:255];
    reg [7:0]                       fifo_wr_ptr;
    reg [7:0]                       fifo_rd_ptr;
    reg [7:0]                       fifo_cnt;
    reg [S_DATA_WIDTH-1:0]          data_shift_reg;
    reg [S_KEEP_WIDTH-1:0]          keep_shift_reg;
    reg [7:0]                       data_shift_count;
    reg                             packet_ending;

    // FIFO control signals
    wire                            fifo_full;
    wire                            fifo_empty;
    wire                            fifo_push;
    wire                            fifo_pop;

    assign fifo_full = (fifo_cnt == 255);
    assign fifo_empty = (fifo_cnt == 0);
    assign fifo_push = s_axis_tvalid && !fifo_full;
    assign fifo_pop = m_axis_tready && !fifo_empty && m_axis_tvalid_reg;

    // FIFO logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_wr_ptr <= 8'b0;
            fifo_rd_ptr <= 8'b0;
            fifo_cnt <= 8'b0;
        end else begin
            if (fifo_push && !fifo_pop) begin
                data_fifo[fifo_wr_ptr] <= s_axis_tdata_reg;
                keep_fifo[fifo_wr_ptr] <= s_axis_tkeep_reg;
                last_fifo[fifo_wr_ptr] <= s_axis_tlast_reg;
                id_fifo[fifo_wr_ptr] <= s_axis_tid_reg;
                dest_fifo[fifo_wr_ptr] <= s_axis_tdest_reg;
                user_fifo[fifo_wr_ptr] <= s_axis_tuser_reg;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                fifo_cnt <= fifo_cnt + 1;
            end else if (!fifo_push && fifo_pop) begin
                fifo_rd_ptr <= fifo_rd_ptr + 1;
                fifo_cnt <= fifo_cnt - 1;
            end else if (fifo_push && fifo_pop) begin
                data_fifo[fifo_wr_ptr] <= s_axis_tdata_reg;
                keep_fifo[fifo_wr_ptr] <= s_axis_tkeep_reg;
                last_fifo[fifo_wr_ptr] <= s_axis_tlast_reg;
                id_fifo[fifo_wr_ptr] <= s_axis_tid_reg;
                dest_fifo[fifo_wr_ptr] <= s_axis_tdest_reg;
                user_fifo[fifo_wr_ptr] <= s_axis_tuser_reg;
                fifo_wr_ptr <= fifo_wr_ptr + 1;
                // fifo_rd_ptr remains unchanged
                // fifo_cnt remains unchanged
            end
        end
    end

    // Register input signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axis_tdata_reg <= {S_DATA_WIDTH{1'b0}};
            s_axis_tkeep_reg <= {S_KEEP_WIDTH{1'b0}};
            s_axis_tlast_reg <= 1'b0;
            s_axis_tid_reg <= {ID_WIDTH{1'b0}};
            s_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
            s_axis_tuser_reg <= {USER_WIDTH{1'b0}};
        end else begin
            if (s_axis_tvalid) begin
                s_axis_tdata_reg <= s_axis_tdata;
                s_axis_tkeep_reg <= s_axis_tkeep;
                s_axis_tlast_reg <= s_axis_tlast;
                s_axis_tid_reg <= s_axis_tid;
                s_axis_tdest_reg <= s_axis_tdest;
                s_axis_tuser_reg <= s_axis_tuser;
            end
        end
    end

    // Shift register logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_shift_reg <= {S_DATA_WIDTH{1'b0}};
            keep_shift_reg <= {S_KEEP_WIDTH{1'b0}};
            data_shift_count <= 8'b0;
            packet_ending <= 1'b0;
        end else begin
            if (fifo_pop) begin
                data_shift_reg <= {data_shift_reg[S_DATA_WIDTH-1-M_DATA_WIDTH:S_DATA_WIDTH-M_DATA_WIDTH-1], data_fifo[fifo_rd_ptr]};
                keep_shift_reg <= {keep_shift_reg[S_KEEP_WIDTH-1-M_KEEP_WIDTH:S_KEEP_WIDTH-M_KEEP_WIDTH-1], keep_fifo[fifo_rd_ptr]};
                if (last_fifo[fifo_rd_ptr]) begin
                    packet_ending <= 1'b1;
                end
                if (data_shift_count == (S_DATA_WIDTH / M_DATA_WIDTH) - 1) begin
                    data_shift_count <= 8'b0;
                end else begin
                    data_shift_count <= data_shift_count + 1;
                end
            end
        end
    end

    // Output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            m_axis_tdata_reg <= {M_DATA_WIDTH{1'b0}};
            m_axis_tkeep_reg <= {M_KEEP_WIDTH{1'b0}};
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
            m_axis_tid_reg <= {ID_WIDTH{1'b0}};
            m_axis_tdest_reg <= {DEST_WIDTH{1'b0}};
            m_axis_tuser_reg <= {USER_WIDTH{1'b0}};
        end else begin
            if (fifo_pop) begin
                m_axis_tdata_reg <= data_shift_reg[M_DATA_WIDTH-1:0];
                m_axis_tkeep_reg <= keep_shift_reg[M_KEEP_WIDTH-1:0];
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tlast_reg <= packet_ending;
                m_axis_tid_reg <= id_fifo[fifo_rd_ptr];
                m_axis_tdest_reg <= dest_fifo[fifo_rd_ptr];
                m_axis_tuser_reg <= user_fifo[fifo_rd_ptr];
            end else if (m_axis_tready) begin
                m_axis_tvalid_reg <= 1'b0;
                m_axis_tlast_reg <= 1'b0;
            end
        end
    end

    // Output assignments
    assign s_axis_tready = !fifo_full;
    assign m_axis_tdata = m_axis_tdata_reg;
    assign m_axis_tkeep = m_axis_tkeep_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    assign m_axis_tid = m_axis_tid_reg;
    assign m_axis_tdest = m_axis_tdest_reg;
    assign m_axis_tuser = m_axis_tuser_reg;

endmodule
