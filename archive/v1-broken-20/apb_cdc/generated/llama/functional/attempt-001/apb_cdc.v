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

    reg [ADDR_WIDTH-1:0]        fifo_addr [0:2**LOG_DEPTH-1];
    reg [DATA_WIDTH-1:0]        fifo_wdata [0:2**LOG_DEPTH-1];
    reg [DATA_WIDTH/8-1:0]      fifo_wstrb [0:2**LOG_DEPTH-1];
    reg [2:0]                   fifo_pprot [0:2**LOG_DEPTH-1];
    reg                         fifo_write [0:2**LOG_DEPTH-1];
    reg                         fifo_valid [0:2**LOG_DEPTH-1];
    reg                         fifo_ready [0:2**LOG_DEPTH-1];
    reg [DATA_WIDTH-1:0]        fifo_rdata [0:2**LOG_DEPTH-1];
    reg                         fifo_rvalid [0:2**LOG_DEPTH-1];

    reg                         src_pready_int;
    reg [DATA_WIDTH-1:0]        src_prdata_int;
    reg                         src_pslverr_int;

    reg                         dst_psel_int;
    reg                         dst_penable_int;
    reg                         dst_pwrite_int;
    reg [ADDR_WIDTH-1:0]        dst_paddr_int;
    reg [DATA_WIDTH-1:0]        dst_pwdata_int;
    reg [DATA_WIDTH/8-1:0]      dst_pstrb_int;
    reg [2:0]                   dst_pprot_int;

    reg [LOG_DEPTH-1:0]         write_ptr;
    reg [LOG_DEPTH-1:0]         read_ptr;

    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_pready_int <= 1'b0;
            src_prdata_int <= {DATA_WIDTH{1'b0}};
            src_pslverr_int <= 1'b0;
            write_ptr <= {LOG_DEPTH{1'b0}};
            read_ptr <= {LOG_DEPTH{1'b0}};
            for (int i = 0; i < 2**LOG_DEPTH; i++) begin
                fifo_valid[i] <= 1'b0;
                fifo_ready[i] <= 1'b0;
                fifo_rvalid[i] <= 1'b0;
            end
        end else if (src_psel_i && src_penable_i) begin
            if (!fifo_valid[write_ptr]) begin
                fifo_addr[write_ptr] <= src_paddr_i;
                fifo_wdata[write_ptr] <= src_pwdata_i;
                fifo_wstrb[write_ptr] <= src_pstrb_i;
                fifo_pprot[write_ptr] <= src_pprot_i;
                fifo_write[write_ptr] <= src_pwrite_i;
                fifo_valid[write_ptr] <= 1'b1;
                write_ptr <= write_ptr + 1;
                if (write_ptr == 2**LOG_DEPTH-1) begin
                    write_ptr <= {LOG_DEPTH{1'b0}};
                end
            end
            src_pready_int <= 1'b1;
        end else begin
            src_pready_int <= 1'b0;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_psel_int <= 1'b0;
            dst_penable_int <= 1'b0;
            dst_pwrite_int <= 1'b0;
            dst_paddr_int <= {ADDR_WIDTH{1'b0}};
            dst_pwdata_int <= {DATA_WIDTH{1'b0}};
            dst_pstrb_int <= {DATA_WIDTH/8{1'b0}};
            dst_pprot_int <= {3{1'b0}};
            read_ptr <= {LOG_DEPTH{1'b0}};
            for (int i = 0; i < 2**LOG_DEPTH; i++) begin
                fifo_ready[i] <= 1'b0;
                fifo_rvalid[i] <= 1'b0;
            end
        end else if (fifo_valid[read_ptr] && !fifo_ready[read_ptr]) begin
            dst_psel_int <= 1'b1;
            dst_penable_int <= 1'b1;
            dst_pwrite_int <= fifo_write[read_ptr];
            dst_paddr_int <= fifo_addr[read_ptr];
            dst_pwdata_int <= fifo_wdata[read_ptr];
            dst_pstrb_int <= fifo_wstrb[read_ptr];
            dst_pprot_int <= fifo_pprot[read_ptr];
            if (dst_pready_i) begin
                fifo_ready[read_ptr] <= 1'b1;
                read_ptr <= read_ptr + 1;
                if (read_ptr == 2**LOG_DEPTH-1) begin
                    read_ptr <= {LOG_DEPTH{1'b0}};
                end
            end
        end else if (fifo_ready[read_ptr] && fifo_rvalid[read_ptr]) begin
            src_prdata_int <= fifo_rdata[read_ptr];
            src_pslverr_int <= dst_pslverr_i;
            fifo_rvalid[read_ptr] <= 1'b0;
            fifo_valid[read_ptr] <= 1'b0;
            read_ptr <= read_ptr + 1;
            if (read_ptr == 2**LOG_DEPTH-1) begin
                read_ptr <= {LOG_DEPTH{1'b0}};
            end
        end else begin
            dst_psel_int <= 1'b0;
            dst_penable_int <= 1'b0;
        end
        if (dst_pready_i && fifo_ready[read_ptr]) begin
            fifo_rdata[read_ptr] <= dst_prdata_i;
            fifo_rvalid[read_ptr] <= 1'b1;
        end
    end

    assign src_pready_o = src_pready_int;
    assign src_prdata_o = src_prdata_int;
    assign src_pslverr_o = src_pslverr_int;
    assign dst_psel_o = dst_psel_int;
    assign dst_penable_o = dst_penable_int;
    assign dst_pwrite_o = dst_pwrite_int;
    assign dst_paddr_o = dst_paddr_int;
    assign dst_pwdata_o = dst_pwdata_int;
    assign dst_pstrb_o = dst_pstrb_int;
    assign dst_pprot_o = dst_pprot_int;

endmodule
