module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input  [WIDTH-1:0]     dst_data_i_unused, // Not in spec, but let's check... actually spec doesn't have this
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);
endmodule

input                  src_rst_ni,
input  [WIDTH-1:0]     src_data_i,
input                  src_valid_i,
output                 src_ready_o,
input                  dst_rst_ni,
input  [WIDTH-1:0]     dst_data_i_unused, // NO - this is not in the spec
output [WIDTH-1:0]     dst_data_o,
output                 dst_valid_o,
input                  dst_ready_i

input                  src_rst_ni,
input  [WIDTH-1:0]     src_data_i,
input                  src_valid_i,
output                 src_ready_o,
input                  dst_rst_ni,
input  [WIDTH-1:0]     dst_data_i_unused, // NO
output [WIDTH-1:0]     dst_data_o,
output                 dst_valid_o,
input                  dst_ready_i

module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync3;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync4;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_bin;
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray;
    wire src_full;
    wire src_wr_en;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync3;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync4;
    reg [PTR_WIDTH-1:0] src_wr_ptr_bin;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray;
    wire dst_empty;
    wire dst_rd_en;

    // Gray code conversion
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    assign src_wr_ptr_gray = bin2gray(src_wr_ptr);
    assign dst_rd_ptr_gray = bin2gray(dst_rd_ptr);

    // Source domain logic
    assign src_wr_en = src_valid_i & src_ready_o;
    assign src_full = (src_wr_ptr_gray == dst_rd_ptr_gray_sync4) && 
                      (src_wr_ptr[PTR_WIDTH-1] != dst_rd_ptr_bin[PTR_WIDTH-1]);

    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (src_wr_en) begin
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_wr_en) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Synchronize dst_rd_ptr_gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync3 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync4 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_gray_sync1 <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync2 <= dst_rd_ptr_gray_sync1;
            dst_rd_ptr_gray_sync3 <= dst_rd_ptr_gray_sync2;
            dst_rd_ptr_gray_sync4 <= dst_rd_ptr_gray_sync3;
        end
    end

    assign dst_rd_ptr_bin = gray2bin(dst_rd_ptr_gray_sync4);

    // Destination domain logic
    assign dst_empty = (dst_rd_ptr_gray == src_wr_ptr_gray_sync4) && 
                       (dst_rd_ptr[PTR_WIDTH-1] != src_wr_ptr_bin[PTR_WIDTH-1]);

    assign dst_rd_en = dst_valid_o & dst_ready_i;

    assign dst_valid_o = ~dst_empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
        end else if (dst_rd_en) begin
            dst_rd_ptr <= dst_rd_ptr + 1'b1;
        end
    end

    always @(posedge dst_clk_i) begin
        if (dst_rd_en) begin
            dst_data_o <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
        end
    end

    // Synchronize src_wr_ptr_gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync3 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync4 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_gray_sync1 <= src_wr_ptr_gray;
            src_wr_ptr_gray_sync2 <= src_wr_ptr_gray_sync1;
            src_wr_ptr_gray_sync3 <= src_wr_ptr_gray_sync2;
            src_wr_ptr_gray_sync4 <= src_wr_ptr_gray_sync3;
        end
    end

    assign src_wr_ptr_bin = gray2bin(src_wr_ptr_gray_sync4);

endmodule

module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync3;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync4;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_bin;
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray;
    wire src_full;
    wire src_wr_en;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [WIDTH-1:0] dst_data_reg;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync3;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync4;
    reg [PTR_WIDTH-1:0] src_wr_ptr_bin;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray;
    wire dst_empty;
    wire dst_rd_en;

    // Gray code conversion
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    assign src_wr_ptr_gray = bin2gray(src_wr_ptr);
    assign dst_rd_ptr_gray = bin2gray(dst_rd_ptr);

    // Source domain logic
    assign src_wr_en = src_valid_i & src_ready_o;
    assign src_full = (src_wr_ptr_gray == dst_rd_ptr_gray_sync4) && 
                      (src_wr_ptr[PTR_WIDTH-1] != dst_rd_ptr_bin[PTR_WIDTH-1]);

    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (src_wr_en) begin
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_wr_en) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Synchronize dst_rd_ptr_gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync3 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync4 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_gray_sync1 <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync2 <= dst_rd_ptr_gray_sync1;
            dst_rd_ptr_gray_sync3 <= dst_rd_ptr_gray_sync2;
            dst_rd_ptr_gray_sync4 <= dst_rd_ptr_gray_sync3;
        end
    end

    assign dst_rd_ptr_bin = gray2bin(dst_rd_ptr_gray_sync4);

    // Destination domain logic
    assign dst_empty = (dst_rd_ptr_gray == src_wr_ptr_gray_sync4) && 
                       (dst_rd_ptr[PTR_WIDTH-1] != src_wr_ptr_bin[PTR_WIDTH-1]);

    assign dst_rd_en = dst_valid_o & dst_ready_i;

    assign dst_valid_o = ~dst_empty;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
        end else begin
            if (dst_rd_en) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end
            if (!dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
            end
        end
    end

    assign dst_data_o = dst_data_reg;

    // Synchronize src_wr_ptr_gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync3 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync4 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_gray_sync1 <= src_wr_ptr_gray;
            src_wr_ptr_gray_sync2 <= src_wr_ptr_gray_sync1;
            src_wr_ptr_gray_sync3 <= src_wr_ptr_gray_sync2;
            src_wr_ptr_gray_sync4 <= src_wr_ptr_gray_sync3;
        end
    end

    assign src_wr_ptr_bin = gray2bin(src_wr_ptr_gray_sync4);

endmodule

module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    localparam DEPTH = 1 << LOG_DEPTH;
    localparam PTR_WIDTH = LOG_DEPTH + 1;

    // Source domain
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] src_wr_ptr;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync3;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_gray_sync4;
    reg [PTR_WIDTH-1:0] dst_rd_ptr_bin;
    wire [PTR_WIDTH-1:0] src_wr_ptr_gray;
    wire src_full;
    wire src_wr_en;

    // Destination domain
    reg [PTR_WIDTH-1:0] dst_rd_ptr;
    reg [WIDTH-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync1;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync2;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync3;
    reg [PTR_WIDTH-1:0] src_wr_ptr_gray_sync4;
    reg [PTR_WIDTH-1:0] src_wr_ptr_bin;
    wire [PTR_WIDTH-1:0] dst_rd_ptr_gray;
    wire dst_empty;
    wire dst_rd_en;

    // Gray code conversion
    function [PTR_WIDTH-1:0] bin2gray;
        input [PTR_WIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [PTR_WIDTH-1:0] gray2bin;
        input [PTR_WIDTH-1:0] gray;
        reg [PTR_WIDTH-1:0] bin;
        integer i;
        begin
            bin[PTR_WIDTH-1] = gray[PTR_WIDTH-1];
            for (i = PTR_WIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    assign src_wr_ptr_gray = bin2gray(src_wr_ptr);
    assign dst_rd_ptr_gray = bin2gray(dst_rd_ptr);

    // Source domain logic
    assign src_wr_en = src_valid_i & src_ready_o;
    assign src_full = (src_wr_ptr_gray == dst_rd_ptr_gray_sync4) && 
                      (src_wr_ptr[PTR_WIDTH-1] != dst_rd_ptr_bin[PTR_WIDTH-1]);

    assign src_ready_o = ~src_full;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_wr_ptr <= {PTR_WIDTH{1'b0}};
        end else if (src_wr_en) begin
            src_wr_ptr <= src_wr_ptr + 1'b1;
        end
    end

    always @(posedge src_clk_i) begin
        if (src_wr_en) begin
            mem[src_wr_ptr[LOG_DEPTH-1:0]] <= src_data_i;
        end
    end

    // Synchronize dst_rd_ptr_gray to source domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_rd_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync3 <= {PTR_WIDTH{1'b0}};
            dst_rd_ptr_gray_sync4 <= {PTR_WIDTH{1'b0}};
        end else begin
            dst_rd_ptr_gray_sync1 <= dst_rd_ptr_gray;
            dst_rd_ptr_gray_sync2 <= dst_rd_ptr_gray_sync1;
            dst_rd_ptr_gray_sync3 <= dst_rd_ptr_gray_sync2;
            dst_rd_ptr_gray_sync4 <= dst_rd_ptr_gray_sync3;
        end
    end

    assign dst_rd_ptr_bin = gray2bin(dst_rd_ptr_gray_sync4);

    // Destination domain logic
    assign dst_empty = (dst_rd_ptr_gray == src_wr_ptr_gray_sync4) && 
                       (dst_rd_ptr[PTR_WIDTH-1] != src_wr_ptr_bin[PTR_WIDTH-1]);

    assign dst_rd_en = dst_valid_o & dst_ready_i;

    assign dst_valid_o = dst_valid_reg;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_rd_ptr <= {PTR_WIDTH{1'b0}};
            dst_data_reg <= {WIDTH{1'b0}};
            dst_valid_reg <= 1'b0;
        end else begin
            if (dst_rd_en) begin
                dst_rd_ptr <= dst_rd_ptr + 1'b1;
            end
            if (!dst_empty) begin
                dst_data_reg <= mem[dst_rd_ptr[LOG_DEPTH-1:0]];
                dst_valid_reg <= 1'b1;
            end else if (dst_rd_en) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    assign dst_data_o = dst_data_reg;

    // Synchronize src_wr_ptr_gray to destination domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_wr_ptr_gray_sync1 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync2 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync3 <= {PTR_WIDTH{1'b0}};
            src_wr_ptr_gray_sync4 <= {PTR_WIDTH{1'b0}};
        end else begin
            src_wr_ptr_gray_sync1 <= src_wr_ptr_gray;
            src_wr_ptr_gray_sync2 <= src_wr_ptr_gray_sync1;
            src_wr_ptr_gray_sync3 <= src_wr_ptr_gray_sync2;
            src_wr_ptr_gray_sync4 <= src_wr_ptr_gray_sync3;
        end
    end

    assign src_wr_ptr_bin = gray2bin(src_wr_ptr_gray_sync4);

endmodule
