`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Imaginary LLC
// Engineer: Simeon, Dele


module UART_RX #(
    parameter BAUD_RATE = 115200;
    parameter CLOCK_FREQ = 125_000_000;
    parameter CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
)(
    input wire iClk, iRst, iRX_serial
    output wire oRX_done,
    output wire [7:0] oRX_byte
    );

    // state definition
    localparam sIDLE = 3'b000 ;
    localparam sRX_START = 3'b001;
    localparam sRX_RECEIVING = 3'B010;
    localparam sRX_STOP = 3'b011;
    localparam sRX_DONE = 3'b100;

    // state register and internal register
    reg rCurrent_state, rNext_state;
    reg [$clog2(CLKS_PER_BIT) - 1: 0] rCycles_bit_current, wCycles_bit_next; // current = output of reg, next = input of reg
    reg [3:0] rBit_current, rBit_next;
    reg [7:0] rBuffer_current, wBuffer_next;
    // Double-register the input wire to prevent metastability issues
    reg rRx1, rRx2;

    always @(posedge iClk) begin
        rRx1 <= iRxSerial;
        rRx2 <= rRx1;
        if (iRst == 1) begin
            rCurrent_state <= sIDLE;
            rCycles_bit_current <= 0;
            rBit_Current <= 0;
            rButter_current <= 0
        end
        else begin
            rCurrent_state <= wNext_state;
            rCycles_bit_current <= wCycles_bit_next;
            rBit_Current <=wBit_Next;
            rBuffer_current <= wBuffer_next;
        end
    end


    // next state logic
    always @(posedge iClk) begin

        case (rCurrent_state) begin
            sIDLE:

                    // buffer still equals prev one, nothing came yet
                    wBuffer_next <= rBuffer_current;
                    wBit_next <= 0;
                    wCycles_bit_next <= 0;

                    if (rRx2) begin // when itxserial == 1 QUESTION: DO WE HAVE TO DO THIS/?
                        wNext_state <= sRX_START;

                    end
                    else begin
                        wNext_state <= sIDLE;
                    end


                SRX_START:

                    wBit_Next <= rBit_Current;
                    wBuffer_next <= rBuffer_current;
                    if (rCycles_bit_current < CLKS_PER_BIT) begin
                        wCycles_bit_next <= rCycles_bit_current + 1;
                        wNext_state <= SRX_START;
                    end
                    else begin
                        wNext_state <= sRX_RECEIVING;
                        wCycles_bit_next <= 0;
                    end

                sRX_RECEIVING:

                    if (rCycles_bit_current < CLKS_PER_BIT - 1) begin
                        wBit_Next <= rBit_Current;
                        wNext_state <= sRX_RECEIVING;
                        wCycles_bit_next <= rCycles_bit_current + 1;
                        if (rCycles_bit_current < (CLKS_PER_BIT - 1) / 2) // sample at middle begin
                            wBuffer_next <= {rRx2, rBuffer_current[7:1]};
                        end
                        else begin
                            wBuffer_next <= rBuffer_current;
                        end
                    else
                    begin
                        wCycles_bit_next <= 0;
                        wBuffer_next <= rBuffer_current;
                        if (rBit_Current != 7) begin
                            wNext_state <= sRX_RECEIVING;
                            wBit_Next <= rBit_Current + 1;
                        end
                        else begin
                        wNext_state <= sRX_STOP;
                        wBit_Next <= 0; // why 0?
                        end
                    end



                sRX_STOP:

                    wBit_Next <=0;
                    wBuffer_next <= rBuffer_current;
                    if (rCycles_bit_current < CLKS_PER_BIT - 1) begin
                        wCycles_bit_next <= rCycles_bit_current + 1;
                        wFSM_Next <= sRX_STOP;
                    end
                    else begin
                        wCycles_bit_next <= 0;
                        wFSM_Next <= sRX_DONE;
                    end

                sRX_DONE:

                    wCycles_bit_next <=0;
                    wBit_Next <= 0;
                    wBuffer_next <= rBuffer_current;
                    wNext_state <= sIDLE;

            end
        end
    end


    // output logic
    assign oTxDone = (sDONE) ? 1 : 0;
    assign oRX_byte = rBuffer_current;
endmodule
