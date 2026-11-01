module isochronous_spill_register #(
    parameter WIDTH = 8
)(
    input              src_clk_i,
    input              src_rst_ni,
    input              src_valid_i,
    output             src_ready_o,
    input  [WIDTH-1:0] src_data_i,
    input              dst_clk_i,
    input              dst_rst_ni,
    output             dst_valid_o,
    input              dst_ready_i,
    output [WIDTH-1:0] dst_data_o
);

    // Source clock domain
    reg [WIDTH-1:0] src_data_reg;
    reg             src_valid_reg;
    wire            src_ready;

    // Destination clock domain
    reg [WIDTH-1:0] dst_data_reg;
    reg             dst_valid_reg;
    wire            dst_ready;

    // Synchronization of src_ready to dst domain
    reg [1:0] src_ready_sync;
    wire      src_ready_dst;

    // Synchronization of dst_ready to src domain
    reg [1:0] dst_ready_sync;
    wire      dst_ready_src;

    // Synchronization of src_valid to dst domain
    reg [1:0] src_valid_sync;
    wire      src_valid_dst;

    // Synchronization of dst_valid to src domain
    reg [1:0] dst_valid_sync;
    wire      dst_valid_src;

    // Synchronization of src_data to dst domain
    reg [WIDTH-1:0] src_data_sync;

    // Synchronization of dst_data to src domain
    reg [WIDTH-1:0] dst_data_sync;

    // Source domain logic
    assign src_ready_o = src_ready;
    assign src_ready = ~src_valid_reg | dst_ready_src;

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_reg <= 1'b0;
            src_data_reg  <= {WIDTH{1'b0}};
        end else begin
            if (src_valid_i && src_ready) begin
                src_valid_reg <= 1'b1;
                src_data_reg  <= src_data_i;
            end else if (src_valid_reg && dst_ready_src) begin
                src_valid_reg <= 1'b0;
            end
        end
    end

    // Destination domain logic
    assign dst_valid_o = dst_valid_reg;
    assign dst_data_o  = dst_data_reg;
    assign dst_ready   = dst_ready_i;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_reg <= 1'b0;
            dst_data_reg  <= {WIDTH{1'b0}};
        end else begin
            if (src_valid_dst && ~dst_valid_reg && dst_ready) begin
                dst_valid_reg <= 1'b1;
                dst_data_reg  <= src_data_sync;
            end else if (dst_valid_reg && dst_ready) begin
                dst_valid_reg <= 1'b0;
            end
        end
    end

    // Synchronizers
    // src_ready to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_ready_sync <= 2'b00;
        end else begin
            src_ready_sync <= {src_ready_sync[0], src_ready};
        end
    end
    assign src_ready_dst = src_ready_sync[1];

    // dst_ready to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_ready_sync <= 2'b00;
        end else begin
            dst_ready_sync <= {dst_ready_sync[0], dst_ready};
        end
    end
    assign dst_ready_src = dst_ready_sync[1];

    // src_valid to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_valid_sync <= 2'b00;
        end else begin
            src_valid_sync <= {src_valid_sync[0], src_valid_reg};
        end
    end
    assign src_valid_dst = src_valid_sync[1];

    // dst_valid to src domain
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_valid_sync <= 2'b00;
        end else begin
            dst_valid_sync <= {dst_valid_sync[0], dst_valid_reg};
        end
    end
    assign dst_valid_src = dst_valid_sync[1];

    // src_data to dst domain
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            src_data_sync <= {WIDTH{1'b0}};
        end else begin
            src_data_sync <= src_data_reg;
        end
    end

    // dst_data to src domain (not strictly needed for this design, but included for completeness)
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            dst_data_sync <= {WIDTH{1'b0}};
        end else begin
            dst_data_sync <= dst_data_reg;
        end
    end

endmodule
