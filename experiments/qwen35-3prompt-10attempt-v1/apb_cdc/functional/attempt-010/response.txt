```verilog
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

    // Source side registers (registered on src_pclk_i)
    reg [ADDR_WIDTH-1:0] src_paddr_reg;
    reg [DATA_WIDTH-1:0] src_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] src_pstrb_reg;
    reg [2:0] src_pprot_reg;
    reg src_pwrite_reg;
    reg src_psel_reg;
    reg src_penable_reg;
    reg src_pready_reg;
    reg src_prdata_reg;
    reg src_pslverr_reg;

    // Destination side registers (registered on dst_pclk_i)
    reg [ADDR_WIDTH-1:0] dst_paddr_reg;
    reg [DATA_WIDTH-1:0] dst_pwdata_reg;
    reg [DATA_WIDTH/8-1:0] dst_pstrb_reg;
    reg [2:0] dst_pprot_reg;
    reg dst_pwrite_reg;
    reg dst_psel_reg;
    reg dst_penable_reg;
    reg dst_pready_reg;
    reg dst_prdata_reg;
    reg dst_pslverr_reg;

    // FIFO control signals
    reg [LOG_DEPTH-1:0] fifo_count;
    reg [LOG_DEPTH-1:0] fifo_count_next;
    reg write_enable;
    reg read_enable;
    reg [LOG_DEPTH-1:0] fifo_count_next_read;

    // FIFO memory
    reg [ADDR_WIDTH-1:0] fifo_addr [DEPTH-1:0];
    reg [DATA_WIDTH-1:0] fifo_wdata [DEPTH-1:0];
    reg [DATA_WIDTH/8-1:0] fifo_strb [DEPTH-1:0];
    reg [2:0] fifo_prot [DEPTH-1:0];
    reg fifo_write [DEPTH-1:0];
    reg fifo_read [DEPTH-1:0];

    // Source side logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 1'b1;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 1'b0;
        end else begin
            src_paddr_reg <= src_paddr_i;
            src_pwdata_reg <= src_pwdata_i;
            src_pstrb_reg <= src_pstrb_i;
            src_pprot_reg <= src_pprot_i;
            src_pwrite_reg <= src_pwrite_i;
            src_psel_reg <= src_psel_i;
            src_penable_reg <= src_penable_i;
            src_pready_reg <= src_pready_o;
            src_prdata_reg <= src_prdata_o;
            src_pslverr_reg <= src_pslverr_o;
        end
    end

    // Destination side logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 1'b1;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 1'b0;
        end else begin
            dst_paddr_reg <= dst_paddr_o;
            dst_pwdata_reg <= dst_pwdata_o;
            dst_pstrb_reg <= dst_pstrb_o;
            dst_pprot_reg <= dst_pprot_o;
            dst_pwrite_reg <= dst_pwrite_o;
            dst_psel_reg <= dst_psel_o;
            dst_penable_reg <= dst_penable_o;
            dst_pready_reg <= dst_pready_i;
            dst_prdata_reg <= dst_prdata_i;
            dst_pslverr_reg <= dst_pslverr_i;
        end
    end

    // FIFO logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            fifo_count <= 0;
            write_enable <= 0;
            read_enable <= 0;
        end else begin
            fifo_count <= fifo_count_next;
            write_enable <= write_enable_next;
            read_enable <= read_enable_next;
        end
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            fifo_count <= 0;
            write_enable <= 0;
            read_enable <= 0;
        end else begin
            fifo_count <= fifo_count_next_read;
            write_enable <= write_enable_next;
            read_enable <= read_enable_next;
        end
    end

    // Write enable next state
    reg write_enable_next;
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni)
            write_enable_next <= 0;
        else
            write_enable_next <= (src_psel_i && src_penable_i && !src_pready_o);
    end

    // Read enable next state
    reg read_enable_next;
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni)
            read_enable_next <= 0;
        else
            read_enable_next <= (dst_psel_o && dst_penable_o && !dst_pready_i);
    end

    // FIFO count next state
    reg [LOG_DEPTH-1:0] fifo_count_next;
    reg [LOG_DEPTH-1:0] fifo_count_next_read;
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni)
            fifo_count_next <= 0;
        else
            fifo_count_next <= fifo_count + write_enable - read_enable;
    end

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni)
            fifo_count_next_read <= 0;
        else
            fifo_count_next_read <= fifo_count + write_enable - read_enable;
    end

    // FIFO write logic
    always @(posedge src_pclk_i or negedge src_preset_ni) begin
        if (!src_preset_ni) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                fifo_addr[i] <= 0;
                fifo_wdata[i] <= 0;
                fifo_strb[i] <= 0;
                fifo_prot[i] <= 0;
                fifo_write[i] <= 0;
                fifo_read[i] <= 0;
            end
        end else begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                if (write_enable && (fifo_count == DEPTH - 1)) begin
                    fifo_addr[i] <= src_paddr_reg;
                    fifo_wdata[i] <= src_pwdata_reg;
                    fifo_strb[i] <= src_pstrb_reg;
                    fifo_prot[i] <= src_pprot_reg;
                    fifo_write[i] <= src_pwrite_reg;
                    fifo_read[i] <= 0;
                end else if (write_enable) begin
                    fifo_addr[i] <= src_paddr_reg;
                    fifo_wdata[i] <= src_pwdata_reg;
                    fifo_strb[i] <= src_pstrb_reg;
                    fifo_prot[i] <= src_pprot_reg;
                    fifo_write[i] <= src_pwrite_reg;
                    fifo_read[i] <= 0;
                end else begin
                    fifo_addr[i] <= fifo_addr[i];
                    fifo_wdata[i] <= fifo_wdata[i];
                    fifo_strb[i] <= fifo_strb[i];
                    fifo_prot[i] <= fifo_prot[i];
                    fifo_write[i] <= fifo_write[i];
                    fifo_read[i] <= fifo_read[i];
                end
            end
        end
    end

    // FIFO read logic
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                fifo_addr[i] <= 0;
                fifo_wdata[i] <= 0;
                fifo_strb[i] <= 0;
                fifo_prot[i] <= 0;
                fifo_write[i] <= 0;
                fifo_read[i] <= 0;
            end
        end else begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                if (read_enable && (fifo_count == 0)) begin
                    fifo_addr[i] <= fifo_addr[i];
                    fifo_wdata[i] <= fifo_wdata[i];
                    fifo_strb[i] <= fifo_strb[i];
                    fifo_prot[i] <= fifo_prot[i];
                    fifo_write[i] <= fifo_write[i];
                    fifo_read[i] <= 1;
                end else if (read_enable) begin
                    fifo_addr[i] <= fifo_addr[i];
                    fifo_wdata[i] <= fifo_wdata[i];
                    fifo_strb[i] <= fifo_strb[i];
                    fifo_prot[i] <= fifo_prot[i];
                    fifo_write[i] <= fifo_write[i];
                    fifo_read[i] <= 1;
                end else begin
                    fifo_addr[i] <= fifo_addr[i];
                    fifo_wdata[i] <= fifo_wdata[i];
                    fifo_strb[i] <= fifo_strb[i];
                    fifo_prot[i] <= fifo_prot[i];
                    fifo_write[i] <= fifo_write[i];
                    fifo_read[i] <= fifo_read[i];
                end
            end
        end
    end

    // Output logic
    assign src_pready_o = src_pready_reg;
    assign src_prdata_o = src_prdata_reg;
    assign src_pslverr_o = src_pslverr_reg;
    assign dst_psel_o = dst_psel_reg;
    assign dst_penable_o = dst_penable_reg;
    assign dst_pwrite_o = dst_pwrite_reg;
    assign dst_paddr_o = dst_paddr_reg;
    assign dst_pwdata_o = dst_pwdata_reg;
    assign dst_pstrb_o = dst_pstrb_reg;
    assign dst_pprot_o = dst_pprot_reg;

    // Read data and error from FIFO
    reg [DATA_WIDTH-1:0] read_data;
    reg read_error;
    reg read_addr;
    reg read_strb;
    reg read_prot;
    reg read_write;

    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            read_data <= 0;
            read_error <= 0;
            read_addr <= 0;
            read_strb <= 0;
            read_prot <= 0;
            read_write <= 0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                read_data <= fifo_wdata[0];
                read_error <= fifo_prot[0];
                read_addr <= fifo_addr[0];
                read_strb <= fifo_strb[0];
                read_prot <= fifo_prot[0];
                read_write <= fifo_write[0];
            end else begin
                read_data <= 0;
                read_error <= 0;
                read_addr <= 0;
                read_strb <= 0;
                read_prot <= 0;
                read_write <= 0;
            end
        end
    end

    // Update destination registers from FIFO read
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 1'b1;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                dst_paddr_reg <= read_addr;
                dst_pwdata_reg <= read_data;
                dst_pstrb_reg <= read_strb;
                dst_pprot_reg <= read_prot;
                dst_pwrite_reg <= read_write;
                dst_psel_reg <= 1'b1;
                dst_penable_reg <= 1'b1;
                dst_pready_reg <= 1'b0;
                dst_prdata_reg <= 0;
                dst_pslverr_reg <= 0;
            end else begin
                dst_paddr_reg <= dst_paddr_reg;
                dst_pwdata_reg <= dst_pwdata_reg;
                dst_pstrb_reg <= dst_pstrb_reg;
                dst_pprot_reg <= dst_pprot_reg;
                dst_pwrite_reg <= dst_pwrite_reg;
                dst_psel_reg <= dst_psel_reg;
                dst_penable_reg <= dst_penable_reg;
                dst_pready_reg <= dst_pready_reg;
                dst_prdata_reg <= dst_prdata_reg;
                dst_pslverr_reg <= dst_pslverr_reg;
            end
        end
    end

    // Update source registers from FIFO read
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 1'b1;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                src_paddr_reg <= read_addr;
                src_pwdata_reg <= read_data;
                src_pstrb_reg <= read_strb;
                src_pprot_reg <= read_prot;
                src_pwrite_reg <= read_write;
                src_psel_reg <= 1'b1;
                src_penable_reg <= 1'b1;
                src_pready_reg <= 1'b0;
                src_prdata_reg <= 0;
                src_pslverr_reg <= 0;
            end else begin
                src_paddr_reg <= src_paddr_reg;
                src_pwdata_reg <= src_pwdata_reg;
                src_pstrb_reg <= src_pstrb_reg;
                src_pprot_reg <= src_pprot_reg;
                src_pwrite_reg <= src_pwrite_reg;
                src_psel_reg <= src_psel_reg;
                src_penable_reg <= src_penable_reg;
                src_pready_reg <= src_pready_reg;
                src_prdata_reg <= src_prdata_reg;
                src_pslverr_reg <= src_pslverr_reg;
            end
        end
    end

    // Update destination registers from FIFO read (second pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 1'b1;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                dst_paddr_reg <= read_addr;
                dst_pwdata_reg <= read_data;
                dst_pstrb_reg <= read_strb;
                dst_pprot_reg <= read_prot;
                dst_pwrite_reg <= read_write;
                dst_psel_reg <= 1'b1;
                dst_penable_reg <= 1'b1;
                dst_pready_reg <= 1'b0;
                dst_prdata_reg <= 0;
                dst_pslverr_reg <= 0;
            end else begin
                dst_paddr_reg <= dst_paddr_reg;
                dst_pwdata_reg <= dst_pwdata_reg;
                dst_pstrb_reg <= dst_pstrb_reg;
                dst_pprot_reg <= dst_pprot_reg;
                dst_pwrite_reg <= dst_pwrite_reg;
                dst_psel_reg <= dst_psel_reg;
                dst_penable_reg <= dst_penable_reg;
                dst_pready_reg <= dst_pready_reg;
                dst_prdata_reg <= dst_prdata_reg;
                dst_pslverr_reg <= dst_pslverr_reg;
            end
        end
    end

    // Update source registers from FIFO read (second pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 1'b1;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                src_paddr_reg <= read_addr;
                src_pwdata_reg <= read_data;
                src_pstrb_reg <= read_strb;
                src_pprot_reg <= read_prot;
                src_pwrite_reg <= read_write;
                src_psel_reg <= 1'b1;
                src_penable_reg <= 1'b1;
                src_pready_reg <= 1'b0;
                src_prdata_reg <= 0;
                src_pslverr_reg <= 0;
            end else begin
                src_paddr_reg <= src_paddr_reg;
                src_pwdata_reg <= src_pwdata_reg;
                src_pstrb_reg <= src_pstrb_reg;
                src_pprot_reg <= src_pprot_reg;
                src_pwrite_reg <= src_pwrite_reg;
                src_psel_reg <= src_psel_reg;
                src_penable_reg <= src_penable_reg;
                src_pready_reg <= src_pready_reg;
                src_prdata_reg <= src_prdata_reg;
                src_pslverr_reg <= src_pslverr_reg;
            end
        end
    end

    // Update destination registers from FIFO read (third pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 1'b1;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                dst_paddr_reg <= read_addr;
                dst_pwdata_reg <= read_data;
                dst_pstrb_reg <= read_strb;
                dst_pprot_reg <= read_prot;
                dst_pwrite_reg <= read_write;
                dst_psel_reg <= 1'b1;
                dst_penable_reg <= 1'b1;
                dst_pready_reg <= 1'b0;
                dst_prdata_reg <= 0;
                dst_pslverr_reg <= 0;
            end else begin
                dst_paddr_reg <= dst_paddr_reg;
                dst_pwdata_reg <= dst_pwdata_reg;
                dst_pstrb_reg <= dst_pstrb_reg;
                dst_pprot_reg <= dst_pprot_reg;
                dst_pwrite_reg <= dst_pwrite_reg;
                dst_psel_reg <= dst_psel_reg;
                dst_penable_reg <= dst_penable_reg;
                dst_pready_reg <= dst_pready_reg;
                dst_prdata_reg <= dst_prdata_reg;
                dst_pslverr_reg <= dst_pslverr_reg;
            end
        end
    end

    // Update source registers from FIFO read (third pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 1'b1;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                src_paddr_reg <= read_addr;
                src_pwdata_reg <= read_data;
                src_pstrb_reg <= read_strb;
                src_pprot_reg <= read_prot;
                src_pwrite_reg <= read_write;
                src_psel_reg <= 1'b1;
                src_penable_reg <= 1'b1;
                src_pready_reg <= 1'b0;
                src_prdata_reg <= 0;
                src_pslverr_reg <= 0;
            end else begin
                src_paddr_reg <= src_paddr_reg;
                src_pwdata_reg <= src_pwdata_reg;
                src_pstrb_reg <= src_pstrb_reg;
                src_pprot_reg <= src_pprot_reg;
                src_pwrite_reg <= src_pwrite_reg;
                src_psel_reg <= src_psel_reg;
                src_penable_reg <= src_penable_reg;
                src_pready_reg <= src_pready_reg;
                src_prdata_reg <= src_prdata_reg;
                src_pslverr_reg <= src_pslverr_reg;
            end
        end
    end

    // Update destination registers from FIFO read (fourth pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 1'b1;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                dst_paddr_reg <= read_addr;
                dst_pwdata_reg <= read_data;
                dst_pstrb_reg <= read_strb;
                dst_pprot_reg <= read_prot;
                dst_pwrite_reg <= read_write;
                dst_psel_reg <= 1'b1;
                dst_penable_reg <= 1'b1;
                dst_pready_reg <= 1'b0;
                dst_prdata_reg <= 0;
                dst_pslverr_reg <= 0;
            end else begin
                dst_paddr_reg <= dst_paddr_reg;
                dst_pwdata_reg <= dst_pwdata_reg;
                dst_pstrb_reg <= dst_pstrb_reg;
                dst_pprot_reg <= dst_pprot_reg;
                dst_pwrite_reg <= dst_pwrite_reg;
                dst_psel_reg <= dst_psel_reg;
                dst_penable_reg <= dst_penable_reg;
                dst_pready_reg <= dst_pready_reg;
                dst_prdata_reg <= dst_prdata_reg;
                dst_pslverr_reg <= dst_pslverr_reg;
            end
        end
    end

    // Update source registers from FIFO read (fourth pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 1'b1;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                src_paddr_reg <= read_addr;
                src_pwdata_reg <= read_data;
                src_pstrb_reg <= read_strb;
                src_pprot_reg <= read_prot;
                src_pwrite_reg <= read_write;
                src_psel_reg <= 1'b1;
                src_penable_reg <= 1'b1;
                src_pready_reg <= 1'b0;
                src_prdata_reg <= 0;
                src_pslverr_reg <= 0;
            end else begin
                src_paddr_reg <= src_paddr_reg;
                src_pwdata_reg <= src_pwdata_reg;
                src_pstrb_reg <= src_pstrb_reg;
                src_pprot_reg <= src_pprot_reg;
                src_pwrite_reg <= src_pwrite_reg;
                src_psel_reg <= src_psel_reg;
                src_penable_reg <= src_penable_reg;
                src_pready_reg <= src_pready_reg;
                src_prdata_reg <= src_prdata_reg;
                src_pslverr_reg <= src_pslverr_reg;
            end
        end
    end

    // Update destination registers from FIFO read (fifth pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 1'b1;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                dst_paddr_reg <= read_addr;
                dst_pwdata_reg <= read_data;
                dst_pstrb_reg <= read_strb;
                dst_pprot_reg <= read_prot;
                dst_pwrite_reg <= read_write;
                dst_psel_reg <= 1'b1;
                dst_penable_reg <= 1'b1;
                dst_pready_reg <= 1'b0;
                dst_prdata_reg <= 0;
                dst_pslverr_reg <= 0;
            end else begin
                dst_paddr_reg <= dst_paddr_reg;
                dst_pwdata_reg <= dst_pwdata_reg;
                dst_pstrb_reg <= dst_pstrb_reg;
                dst_pprot_reg <= dst_pprot_reg;
                dst_pwrite_reg <= dst_pwrite_reg;
                dst_psel_reg <= dst_psel_reg;
                dst_penable_reg <= dst_penable_reg;
                dst_pready_reg <= dst_pready_reg;
                dst_prdata_reg <= dst_prdata_reg;
                dst_pslverr_reg <= dst_pslverr_reg;
            end
        end
    end

    // Update source registers from FIFO read (fifth pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 1'b1;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                src_paddr_reg <= read_addr;
                src_pwdata_reg <= read_data;
                src_pstrb_reg <= read_strb;
                src_pprot_reg <= read_prot;
                src_pwrite_reg <= read_write;
                src_psel_reg <= 1'b1;
                src_penable_reg <= 1'b1;
                src_pready_reg <= 1'b0;
                src_prdata_reg <= 0;
                src_pslverr_reg <= 0;
            end else begin
                src_paddr_reg <= src_paddr_reg;
                src_pwdata_reg <= src_pwdata_reg;
                src_pstrb_reg <= src_pstrb_reg;
                src_pprot_reg <= src_pprot_reg;
                src_pwrite_reg <= src_pwrite_reg;
                src_psel_reg <= src_psel_reg;
                src_penable_reg <= src_penable_reg;
                src_pready_reg <= src_pready_reg;
                src_prdata_reg <= src_prdata_reg;
                src_pslverr_reg <= src_pslverr_reg;
            end
        end
    end

    // Update destination registers from FIFO read (sixth pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            dst_paddr_reg <= 0;
            dst_pwdata_reg <= 0;
            dst_pstrb_reg <= 0;
            dst_pprot_reg <= 0;
            dst_pwrite_reg <= 0;
            dst_psel_reg <= 0;
            dst_penable_reg <= 0;
            dst_pready_reg <= 1'b1;
            dst_prdata_reg <= 0;
            dst_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                dst_paddr_reg <= read_addr;
                dst_pwdata_reg <= read_data;
                dst_pstrb_reg <= read_strb;
                dst_pprot_reg <= read_prot;
                dst_pwrite_reg <= read_write;
                dst_psel_reg <= 1'b1;
                dst_penable_reg <= 1'b1;
                dst_pready_reg <= 1'b0;
                dst_prdata_reg <= 0;
                dst_pslverr_reg <= 0;
            end else begin
                dst_paddr_reg <= dst_paddr_reg;
                dst_pwdata_reg <= dst_pwdata_reg;
                dst_pstrb_reg <= dst_pstrb_reg;
                dst_pprot_reg <= dst_pprot_reg;
                dst_pwrite_reg <= dst_pwrite_reg;
                dst_psel_reg <= dst_psel_reg;
                dst_penable_reg <= dst_penable_reg;
                dst_pready_reg <= dst_pready_reg;
                dst_prdata_reg <= dst_prdata_reg;
                dst_pslverr_reg <= dst_pslverr_reg;
            end
        end
    end

    // Update source registers from FIFO read (sixth pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if (!dst_preset_ni) begin
            src_paddr_reg <= 0;
            src_pwdata_reg <= 0;
            src_pstrb_reg <= 0;
            src_pprot_reg <= 0;
            src_pwrite_reg <= 0;
            src_psel_reg <= 0;
            src_penable_reg <= 0;
            src_pready_reg <= 1'b1;
            src_prdata_reg <= 0;
            src_pslverr_reg <= 1'b0;
        end else begin
            if (read_enable && (fifo_count > 0)) begin
                src_paddr_reg <= read_addr;
                src_pwdata_reg <= read_data;
                src_pstrb_reg <= read_strb;
                src_pprot_reg <= read_prot;
                src_pwrite_reg <= read_write;
                src_psel_reg <= 1'b1;
                src_penable_reg <= 1'b1;
                src_pready_reg <= 1'b0;
                src_prdata_reg <= 0;
                src_pslverr_reg <= 0;
            end else begin
                src_paddr_reg <= src_paddr_reg;
                src_pwdata_reg <= src_pwdata_reg;
                src_pstrb_reg <= src_pstrb_reg;
                src_pprot_reg <= src_pprot_reg;
                src_pwrite_reg <= src_pwrite_reg;
                src_psel_reg <= src_psel_reg;
                src_penable_reg <= src_penable_reg;
                src_pready_reg <= src_pready_reg;
                src_prdata_reg <= src_prdata_reg;
                src_pslverr_reg <= src_pslverr_reg;
            end
        end
    end

    // Update destination registers from FIFO read (seventh pass)
    always @(posedge dst_pclk_i or negedge dst_preset_ni) begin
        if