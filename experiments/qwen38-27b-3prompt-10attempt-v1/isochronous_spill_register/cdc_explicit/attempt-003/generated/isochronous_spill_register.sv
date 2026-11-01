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

    // Synchronizers for reset signals
    reg [1:0] src_rst_ni_sync;
    reg [1:0] dst_rst_ni_sync;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_rst_ni_sync <= 2'b00;
        else
            src_rst_ni_sync <= {src_rst_ni_sync[0], src_rst_ni};
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_rst_ni_sync <= 2'b00;
        else
            dst_rst_ni_sync <= {dst_rst_ni_sync[0], dst_rst_ni};
    end

    // Synchronizers for valid/ready signals
    reg [1:0] src_valid_sync;
    reg [1:0] dst_ready_sync;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_valid_sync <= 2'b00;
        else
            src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            dst_ready_sync <= 2'b00;
        else
            dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end

    // Synchronizers for data
    reg [WIDTH-1:0] src_data_sync;
    reg [WIDTH-1:0] src_data_sync_next;

    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni)
            src_data_sync <= {WIDTH{1'b0}};
        else
            src_data_sync <= src_data_sync_next;
    end

    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni)
            src_data_sync_next <= {WIDTH{1'b0}};
        else
            src_data_sync_next <= src_data_i;
    end

    // Internal state
    reg src_valid_int;
    reg dst_ready_int;
    reg [WIDTH-1:0] data_reg;

    // Source domain logic
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_valid_int <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else begin
            if (src_valid_i && dst_ready_sync[1]) begin
                src_valid_int <= 1'b1;
                data_reg <= src_data_i;
            end else if (dst_ready_sync[1]) begin
                src_valid_int <= 1'b0;
            end
        end
    end

    // Destination domain logic
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_ready_int <= 1'b0;
        end else begin
            if (src_valid_sync[1] && dst_ready_i) begin
                dst_ready_int <= 1'b0;
            end else if (src_valid_sync[1]) begin
                dst_ready_int <= 1'b1;
            end
        end
    end

    // Outputs
    assign src_ready_o = dst_ready_sync[1];
    assign dst_valid_o = src_valid_sync[1];
    assign dst_data_o = src_data_sync;

endmodule
