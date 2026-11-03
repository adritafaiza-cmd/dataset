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
    /*
     * AXI input
     */
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
    /*
     * AXI output
     */
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
    /*
     * Pause
     */
    input  wire                   s_pause_req,
    output wire                   s_pause_ack,
    input  wire                   m_pause_req,
    output wire                   m_pause_ack,
    /*
     * Status
     */
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

    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam DEPTH_MASK = DEPTH - 1;
    
    // Total width of the data word stored in RAM
    localparam TOTAL_DATA_WIDTH = DATA_WIDTH + 
                                  (KEEP_ENABLE ? KEEP_WIDTH : 0) +
                                  (LAST_ENABLE ? 1 : 0) +
                                  (ID_ENABLE ? ID_WIDTH : 0) +
                                  (DEST_ENABLE ? DEST_WIDTH : 0) +
                                  (USER_ENABLE ? USER_WIDTH : 0);

    // Internal signals
    wire [TOTAL_DATA_WIDTH-1:0] ram_data;
    wire [ADDR_WIDTH:0] wr_ptr;
    wire [ADDR_WIDTH:0] rd_ptr;
    wire [ADDR_WIDTH:0] wr_ptr_gray;
    wire [ADDR_WIDTH:0] rd_ptr_gray;
    
    // Synchronizers
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
    
    // Write side (s_clk domain)
    reg [ADDR_WIDTH:0] wr_ptr_reg;
    reg [ADDR_WIDTH:0] wr_ptr_gray_reg;
    reg [TOTAL_DATA_WIDTH-1:0] ram_mem [0:DEPTH-1];
    
    // Read side (m_clk domain)
    reg [ADDR_WIDTH:0] rd_ptr_reg;
    reg [ADDR_WIDTH:0] rd_ptr_gray_reg;
    reg [TOTAL_DATA_WIDTH-1:0] rd_data_reg;
    reg rd_valid_reg;
    
    // Status registers
    reg s_overflow_reg;
    reg s_bad_frame_reg;
    reg s_good_frame_reg;
    reg m_overflow_reg;
    reg m_bad_frame_reg;
    reg m_good_frame_reg;
    
    // Pause logic
    reg s_pause_ack_reg;
    reg m_pause_ack_reg;
    
    // Frame tracking for write side
    reg in_frame_reg;
    reg frame_overflow_reg;
    
    // Frame tracking for read side
    reg m_in_frame_reg;
    reg m_frame_overflow_reg;

    // Calculate depth
    wire [ADDR_WIDTH:0] depth = wr_ptr_reg - rd_ptr_reg;
    wire [ADDR_WIDTH:0] depth_commit = wr_ptr_gray_sync2 - rd_ptr_gray_sync2;
    
    // Full and empty conditions
    wire full = (wr_ptr_reg == rd_ptr_gray_sync2);
    wire empty = (rd_ptr_reg == wr_ptr_gray_sync2);
    
    // Write enable
    wire s_write_en = s_axis_tvalid && s_axis_tready;
    
    // Read enable
    wire m_read_en = m_axis_tvalid && m_axis_tready;
    
    // Pause logic
    wire s_pause_active = PAUSE_ENABLE && s_pause_req;
    wire m_pause_active = PAUSE_ENABLE && m_pause_req;
    
    // Effective write enable considering pause
    wire s_write_en_eff = s_write_en && !s_pause_active;
    
    // Effective read enable considering pause
    wire m_read_en_eff = m_read_en && !m_pause_active;
    
    // Tready logic
    wire s_tready_base = !full;
    wire s_tready_drop = DROP_WHEN_FULL;
    wire s_tready_mark = MARK_WHEN_FULL;
    
    assign s_axis_tready = (s_tready_drop || s_tready_mark) ? 1'b1 : s_tready_base;
    
    // Tvalid logic
    assign m_axis_tvalid = rd_valid_reg && !m_pause_active;
    
    // Pause ack
    assign s_pause_ack = s_pause_ack_reg;
    assign m_pause_ack = m_pause_ack_reg;
    
    // Status outputs
    assign s_status_depth = depth;
    assign s_status_depth_commit = depth_commit;
    assign s_status_overflow = s_overflow_reg;
    assign s_status_bad_frame = s_bad_frame_reg;
    assign s_status_good_frame = s_good_frame_reg;
    assign m_status_depth = depth_commit;
    assign m_status_depth_commit = depth_commit;
    assign m_status_overflow = m_overflow_reg;
    assign m_status_bad_frame = m_bad_frame_reg;
    assign m_status_good_frame = m_good_frame_reg;
    
    // Output data
    assign m_axis_tdata = rd_data_reg[DATA_WIDTH-1:0];
    assign m_axis_tkeep = KEEP_ENABLE ? rd_data_reg[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] : {KEEP_WIDTH{1'b0}};
    assign m_axis_tlast = LAST_ENABLE ? rd_data_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] : 1'b0;
    assign m_axis_tid = ID_ENABLE ? rd_data_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)] : {ID_WIDTH{1'b0}};
    assign m_axis_tdest = DEST_ENABLE ? rd_data_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)] : {DEST_WIDTH{1'b0}};
    assign m_axis_tuser = USER_ENABLE ? rd_data_reg[TOTAL_DATA_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)] : {USER_WIDTH{1'b0}};
    
    // Write data packing
    wire [TOTAL_DATA_WIDTH-1:0] wr_data;
    assign wr_data[DATA_WIDTH-1:0] = s_axis_tdata;
    assign wr_data[DATA_WIDTH + KEEP_WIDTH-1:DATA_WIDTH] = KEEP_ENABLE ? s_axis_tkeep : {KEEP_WIDTH{1'b0}};
    assign wr_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)] = LAST_ENABLE ? s_axis_tlast : 1'b0;
    assign wr_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + ID_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0)] = ID_ENABLE ? s_axis_tid : {ID_WIDTH{1'b0}};
    assign wr_data[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + DEST_WIDTH-1 : DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0)] = DEST_ENABLE ? s_axis_tdest : {DEST_WIDTH{1'b0}};
    assign wr_data[TOTAL_DATA_WIDTH-1:DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0) + (LAST_ENABLE ? 1 : 0) + (ID_ENABLE ? ID_WIDTH : 0) + (DEST_ENABLE ? DEST_WIDTH : 0)] = USER_ENABLE ? s_axis_tuser : {USER_WIDTH{1'b0}};
    
    // Gray code conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Write pointer update
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            wr_ptr_reg <= 0;
            wr_ptr_gray_reg <= 0;
            s_overflow_reg <= 0;
            s_bad_frame_reg <= 0;
            s_good_frame_reg <= 0;
            in_frame_reg <= 0;
            frame_overflow_reg <= 0;
            s_pause_ack_reg <= 0;
        end else begin
            // Update pause ack
            if (PAUSE_ENABLE) begin
                s_pause_ack_reg <= s_pause_req;
            end
            
            // Update write pointer
            if (s_write_en_eff) begin
                wr_ptr_reg <= wr_ptr_reg + 1;
                wr_ptr_gray_reg <= bin2gray(wr_ptr_reg + 1);
                
                // Write to RAM
                ram_mem[wr_ptr_reg[ADDR_WIDTH-1:0]] <= wr_data;
                
                // Frame tracking
                if (LAST_ENABLE) begin
                    if (s_axis_tlast) begin
                        in_frame_reg <= 0;
                        if (frame_overflow_reg) begin
                            s_bad_frame_reg <= 1;
                            frame_overflow_reg <= 0;
                        end else begin
                            s_good_frame_reg <= 1;
                        end
                    end else begin
                        in_frame_reg <= 1;
                        if (DROP_OVERSIZE_FRAME && in_frame_reg) begin
                            frame_overflow_reg <= 1;
                        end
                    end
                end
            end else if (s_write_en && full && (DROP_WHEN_FULL || MARK_WHEN_FULL)) begin
                // Overflow condition
                s_overflow_reg <= 1;
                if (MARK_WHEN_FULL && LAST_ENABLE && s_axis_tlast) begin
                    s_good_frame_reg <= 1;
                end
            end
        end
    end
    
    // Synchronize write pointer gray to m_clk domain
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray_reg;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    // Synchronize read pointer gray to s_clk domain
    always @(posedge s_clk or posedge s_rst) begin
        if (s_rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray_reg;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    // Read pointer update
    always @(posedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            rd_ptr_reg <= 0;
            rd_ptr_gray_reg <= 0;
            rd_valid_reg <= 0;
            rd_data_reg <= 0;
            m_overflow_reg <= 0;
            m_bad_frame_reg <= 0;
            m_good_frame_reg <= 0;
            m_in_frame_reg <= 0;
            m_frame_overflow_reg <= 0;
            m_pause_ack_reg <= 0;
        end else begin
            // Update pause ack
            if (PAUSE_ENABLE) begin
                m_pause_ack_reg <= m_pause_req;
            end
            
            // Read from RAM
            if (!empty) begin
                rd_data_reg <= ram_mem[rd_ptr_reg[ADDR_WIDTH-1:0]];
                rd_valid_reg <= 1;
            end
            
            // Update read pointer
            if (m_read_en_eff) begin
                rd_ptr_reg <= rd_ptr_reg + 1;
                rd_ptr_gray_reg <= bin2gray(rd_ptr_reg + 1);
                rd_valid_reg <= 0;
                
                // Frame tracking
                if (LAST_ENABLE) begin
                    if (rd_data_reg[DATA_WIDTH + (KEEP_ENABLE ? KEEP_WIDTH : 0)]) begin
                        m_in_frame_reg <= 0;
                        if (m_frame_overflow_reg) begin
                            m_bad_frame_reg <= 1;
                            m_frame_overflow_reg <= 0;
                        end else begin
                            m_good_frame_reg <= 1;
                        end
                    end else begin
                        m_in_frame_reg <= 1;
                        if (DROP_OVERSIZE_FRAME && m_in_frame_reg) begin
                            m_frame_overflow_reg <= 1;
                        end
                    end
                end
            end
        end
    end

endmodule
