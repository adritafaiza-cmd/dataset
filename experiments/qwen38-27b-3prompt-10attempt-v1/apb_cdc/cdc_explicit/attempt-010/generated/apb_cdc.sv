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
    localparam PTR_W = (LOG_DEPTH == 1) ? 1 : LOG_DEPTH;

    // Source domain state
    reg src_idle;
    reg src_setup;
    reg src_access;
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [DATA_WIDTH-1:0] src_wdata_reg;
    reg [DATA_WIDTH/8-1:0] src_strb_reg;
    reg [2:0] src_prot_reg;
    reg src_write_reg;

    // Destination domain state
    reg dst_idle;
    reg dst_setup;
    reg dst_access;
    reg [ADDR_WIDTH-1:0] dst_addr_reg;
    reg [DATA_WIDTH-1:0] dst_wdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_strb_reg;
    reg [2:0] dst_prot_reg;
    reg dst_write_reg;

    // FIFO control signals
    wire src_fifo_wr_en;
    wire dst_fifo_rd_en;
    wire src_fifo_full;
    wire dst_fifo_empty;

    // CDC synchronizers
    reg [2:0] src_to_dst_sync;
    reg [2:0] dst_to_src_sync;

    // Internal FIFO signals
    wire [ADDR_WIDTH-1:0] fifo_dout_addr;
    wire [DATA_WIDTH-1:0] fifo_dout_wdata;
    wire [DATA_WIDTH/8-1:0] fifo_dout_strb;
    wire [2:0] fifo_dout_prot;
    wire fifo_dout_write;

    // Source domain logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_idle <= 1'b1;
            src_setup <= 1'b0;
            src_access <= 1'b0;
            src_addr_reg <= {ADDR_WIDTH{1'b0}};
            src_wdata_reg <= {DATA_WIDTH{1'b0}};
            src_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            src_prot_reg <= 3'b000;
            src_write_reg <= 1'b0;
        end else begin
            if (src_idle) begin
                if (src_psel_i) begin
                    src_idle <= 1'b0;
                    src_setup <= 1'b1;
                    src_access <= 1'b0;
                    src_addr_reg <= src_paddr_i;
                    src_wdata_reg <= src_pwdata_i;
                    src_strb_reg <= src_pstrb_i;
                    src_prot_reg <= src_pprot_i;
                    src_write_reg <= src_pwrite_i;
                end
            end else if (src_setup) begin
                if (src_penable_i) begin
                    src_setup <= 1'b0;
                    src_access <= 1'b1;
                end
            end else if (src_access) begin
                if (dst_to_src_sync[0]) begin
                    src_idle <= 1'b1;
                    src_setup <= 1'b0;
                    src_access <= 1'b0;
                end
            end
        end
    end

    assign src_pready_o = src_idle | (src_setup && src_penable_i) | (src_access && dst_to_src_sync[0]);
    assign src_prdata_o = fifo_dout_wdata;
    assign src_pslverr_o = fifo_dout_write ? 1'b0 : fifo_dout_prot[0]; // Simplified error mapping

    // Destination domain logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_idle <= 1'b1;
            dst_setup <= 1'b0;
            dst_access <= 1'b0;
            dst_addr_reg <= {ADDR_WIDTH{1'b0}};
            dst_wdata_reg <= {DATA_WIDTH{1'b0}};
            dst_strb_reg <= {(DATA_WIDTH/8){1'b0}};
            dst_prot_reg <= 3'b000;
            dst_write_reg <= 1'b0;
        end else begin
            if (dst_idle) begin
                if (!dst_fifo_empty) begin
                    dst_idle <= 1'b0;
                    dst_setup <= 1'b1;
                    dst_access <= 1'b0;
                    dst_addr_reg <= fifo_dout_addr;
                    dst_wdata_reg <= fifo_dout_wdata;
                    dst_strb_reg <= fifo_dout_strb;
                    dst_prot_reg <= fifo_dout_prot;
                    dst_write_reg <= fifo_dout_write;
                end
            end else if (dst_setup) begin
                dst_access <= 1'b1;
                dst_setup <= 1'b0;
            end else if (dst_access) begin
                if (dst_pready_i) begin
                    dst_idle <= 1'b1;
                    dst_setup <= 1'b0;
                    dst_access <= 1'b0;
                end
            end
        end
    end

    assign dst_psel_o = dst_setup | dst_access;
    assign dst_penable_o = dst_access;
    assign dst_pwrite_o = dst_write_reg;
    assign dst_paddr_o = dst_addr_reg;
    assign dst_pwdata_o = dst_wdata_reg;
    assign dst_pstrb_o = dst_strb_reg;
    assign dst_pprot_o = dst_prot_reg;

    // FIFO write enable (source domain)
    assign src_fifo_wr_en = src_setup && src_penable_i && !src_fifo_full;

    // FIFO read enable (destination domain)
    assign dst_fifo_rd_en = dst_idle && !dst_fifo_empty;

    // CDC synchronizers
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_to_dst_sync <= 3'b000;
        end else begin
            src_to_dst_sync <= {src_to_dst_sync[1:0], src_fifo_wr_en};
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_to_src_sync <= 3'b000;
        end else begin
            dst_to_src_sync <= {dst_to_src_sync[1:0], dst_fifo_rd_en};
        end
    end

    // FIFO implementation
    reg [ADDR_WIDTH-1:0] mem_addr [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] mem_wdata [0:DEPTH-1];
    reg [DATA_WIDTH/8-1:0] mem_strb [0:DEPTH-1];
    reg [2:0] mem_prot [0:DEPTH-1];
    reg mem_write [0:DEPTH-1];
    reg [PTR_W-1:0] wr_ptr;
    reg [PTR_W-1:0] rd_ptr;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            wr_ptr <= {PTR_W{1'b0}};
        end else if (src_fifo_wr_en) begin
            mem_addr[wr_ptr] <= src_addr_reg;
            mem_wdata[wr_ptr] <= src_wdata_reg;
            mem_strb[wr_ptr] <= src_strb_reg;
            mem_prot[wr_ptr] <= src_prot_reg;
            mem_write[wr_ptr] <= src_write_reg;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            rd_ptr <= {PTR_W{1'b0}};
        end else if (dst_fifo_rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    assign fifo_dout_addr = mem_addr[rd_ptr];
    assign fifo_dout_wdata = mem_wdata[rd_ptr];
    assign fifo_dout_strb = mem_strb[rd_ptr];
    assign fifo_dout_prot = mem_prot[rd_ptr];
    assign fifo_dout_write = mem_write[rd_ptr];

    assign src_fifo_full = (wr_ptr == rd_ptr) && (wr_ptr[PTR_W-1] != rd_ptr[PTR_W-1]);
    assign dst_fifo_empty = (wr_ptr == rd_ptr);

endmodule
