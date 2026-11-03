module sync_reset #
(
    parameter N = 2
)
(
    input  wire clk,
    input  wire rst,
    output wire out
);

    // Internal signal to hold the pipeline output
    wire [N-1:0] pipeline_stages;

    // Generate the N-stage pipeline
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_pipeline
            // First stage directly takes the reset input
            if (i == 0) begin
                dff dff_inst_0 (
                    .clk(clk),
                    .rst(rst),
                    .in(rst),
                    .out(pipeline_stages[i])
                );
            end else begin
                dff dff_inst (
                    .clk(clk),
                    .rst(rst),
                    .in(pipeline_stages[i-1]),
                    .out(pipeline_stages[i])
                );
            end
        end
    endgenerate

    // Assign the last stage of the pipeline to the output
    assign out = pipeline_stages[N-1];

endmodule

// N-stage flip-flop pipeline module
module dff (
    input  wire clk,
    input  wire rst,
    input  wire in,
    output wire out
);

    reg stage;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage <= 1'b1;
        end else begin
            stage <= in;
        end
    end

    assign out = stage;

endmodule
