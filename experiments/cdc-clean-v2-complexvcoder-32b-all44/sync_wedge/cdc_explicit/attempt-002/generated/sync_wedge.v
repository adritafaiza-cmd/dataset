module sync_wedge #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  en_i,
    input  serial_i,
    output r_edge_o,
    output f_edge_o,
    output serial_o
);

    // Internal signals
    reg sync_out;
    reg sync_out_d;
    reg rising_edge;
    reg falling_edge;

    // Instantiate the sync_chain module
    sync_chain #(
        .STAGES(STAGES)
    ) sync_chain_inst (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .async_in(serial_i),
        .sync_out(sync_out)
    );

    // Register the synchronized output to detect edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_out_d <= 1'b0;
        end else begin
            sync_out_d <= sync_out;
        end
    end

    // Detect rising and falling edges
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
        end else begin
            rising_edge <= sync_out & ~sync_out_d;
            falling_edge <= ~sync_out & sync_out_d;
        end
    end

    // Generate edge outputs based on enable
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            r_edge_o <= 1'b0;
            f_edge_o <= 1'b0;
        end else begin
            r_edge_o <= en_i & rising_edge;
            f_edge_o <= en_i & falling_edge;
        end
    end

    // Assign the synchronized output
    assign serial_o = sync_out;

endmodule

module sync_chain #(
    parameter STAGES = 2
)(
    input  clk_i,
    input  rst_ni,
    input  async_in,
    output sync_out
);

    // Internal signals
    reg [STAGES-1:0] sync_chain;

    // Synchronize the asynchronous input to the clock domain
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sync_chain <= {STAGES{1'b0}};
        end else begin
            sync_chain[0] <= async_in;
            for (int i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    end

    // Final stage is the synchronized output
    assign sync_out = sync_chain[STAGES-1];

endmodule
