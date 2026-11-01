module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_W = LOG_DEPTH;

    // Source side state
    reg src_idle;
    reg src_busy;
    reg src_read;
    reg [ADDR_WIDTH-1:0] src_addr;
    reg [DATA_WIDTH-1:0] src_wdata;
    reg [DATA_WIDTH/8-1:0] src_strb;
    reg [2:0] src_prot;

    // Destination side state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;
    reg dst_read;
    reg [ADDR_WIDTH-1:0] dst_addr;
    reg [DATA_WIDTH-1:0] dst_wdata;
    reg [DATA_WIDTH/8-1:0] dst_strb;
    reg [2:0] dst_prot;

    // FIFO for request data (source to destination)
    reg [DATA_WIDTH-1:0] fifo_data [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] fifo_addr [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] fifo_strb [0:DEPTH-1];
    reg [2:0] fifo_prot [0:DEPTH-1];
    reg fifo_read_flag [0:DEPTH-1];
    reg [PTR_W-1:0] fifo_wr_ptr;
    reg [PTR_W-1:0] fifo_rd_ptr;
    reg fifo_empty;
    reg fifo_full;

    // FIFO for response data (destination to source)
    reg [DATA_WIDTH-1:0] resp_data [0:DEPTH-1];
    reg resp_err [0:DEPTH-1];
    reg [PTR_W-1:0] resp_wr_ptr;
    reg [PTR_W-1:0] resp_rd_ptr;
    reg resp_empty;
    reg resp_full;

    // Source side outputs
    assign src_pready_o = src_idle;
    assign src_prdata_o = resp_data[resp_rd_ptr];
    assign src_pslverr_o = resp_err[resp_rd_ptr];

    // Destination side outputs
    assign dst_psel_o = dst_setup | dst_access;
    assign dst_penable_o = dst_access;
    assign dst_pwrite_o = ~dst_read;
    assign dst_paddr_o = dst_addr;
    assign dst_pwdata_o = dst_wdata;
    assign dst_pstrb_o = dst_strb;
    assign dst_pprot_o = dst_prot;

    // Source clock domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_busy <= 1'b0;
            src_read <= 1'b0;
            src_addr <= {ADDR_WIDTH{1'b0}};
            src_wdata <= {DATA_WIDTH{1'b0}};
            src_strb <= {(DATA_WIDTH/8){1'b0}};
            src_prot <= 3'b000;
            fifo_wr_ptr <= {PTR_W{1'b0}};
            fifo_empty <= 1'b1;
            fifo_full <= 1'b0;
            resp_rd_ptr <= {PTR_W{1'b0}};
            resp_empty <= 1'b1;
            resp_full <= 1'b0;
        end else begin
            if (src_idle) begin
                if (src_psel_i) begin
                    src_idle <= 1'b0;
                    src_busy <= 1'b1;
                    src_read <= ~src_pwrite_i;
                    src_addr <= src_paddr_i;
                    src_wdata <= src_pwdata_i;
                    src_strb <= src_pstrb_i;
                    src_prot <= src_pprot_i;
                    
                    // Write to FIFO
                    fifo_data[fifo_wr_ptr] <= src_pwdata_i;
                    fifo_addr[fifo_wr_ptr] <= src_paddr_i;
                    fifo_strb[fifo_wr_ptr] <= src_pstrb_i;
                    fifo_prot[fifo_wr_ptr] <= src_pprot_i;
                    fifo_read_flag[fifo_wr_ptr] <= ~src_pwrite_i;
                    fifo_wr_ptr <= fifo_wr_ptr + 1'b1;
                    fifo_empty <= 1'b0;
                    fifo_full <= (fifo_wr_ptr == fifo_rd_ptr) ? 1'b1 : 1'b0;
                end
            end else if (src_busy) begin
                if (!resp_empty) begin
                    src_busy <= 1'b0;
                    src_idle <= 1'b1;
                    resp_rd_ptr <= resp_rd_ptr + 1'b1;
                    resp_empty <= (resp_rd_ptr == resp_wr_ptr) ? 1'b1 : 1'b0;
                    resp_full <= 1'b0;
                end
            end
        end
    end

    // Destination clock domain logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_read <= 1'b0;
            dst_addr <= {ADDR_WIDTH{1'b0}};
            dst_wdata <= {DATA_WIDTH{1'b0}};
            dst_strb <= {(DATA_WIDTH/8){1'b0}};
            dst_prot <= 3'b000;
            fifo_rd_ptr <= {PTR_W{1'b0}};
            resp_wr_ptr <= {PTR_W{1'b0}};
        end else begin
            if (dst_idle) begin
                if (!fifo_empty) begin
                    dst_idle <= 1'b0;
                    dst_setup <= 1'b1;
                    dst_read <= fifo_read_flag[fifo_rd_ptr];
                    dst_addr <= fifo_addr[fifo_rd_ptr];
                    dst_wdata <= fifo_data[fifo_rd_ptr];
                    dst_strb <= fifo_strb[fifo_rd_ptr];
                    dst_prot <= fifo_prot[fifo_rd_ptr];
                end
            end else if (dst_setup) begin
                dst_setup <= 1'b0;
                dst_access <= 1'b1;
            end else if (dst_access) begin
                if (dst_pready_i) begin
                    dst_access <= 1'b0;
                    dst_idle <= 1'b1;
                    
                    // Write response to FIFO
                    resp_data[resp_wr_ptr] <= dst_prdata_i;
                    resp_err[resp_wr_ptr] <= dst_pslverr_i;
                    resp_wr_ptr <= resp_wr_ptr + 1'b1;
                    resp_empty <= 1'b0;
                    resp_full <= (resp_wr_ptr == resp_rd_ptr) ? 1'b1 : 1'b0;
                    
                    // Read from request FIFO
                    fifo_rd_ptr <= fifo_rd_ptr + 1'b1;
                    fifo_empty <= (fifo_rd_ptr == fifo_wr_ptr) ? 1'b1 : 1'b0;
                    fifo_full <= 1'b0;
                end
            end
        end
    end

endmodule
