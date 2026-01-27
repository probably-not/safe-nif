Benchmark

Benchmark run from 2026-01-27 13:28:27.087572Z UTC

## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>macOS</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">Apple M4</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">10</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">24 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.19.4</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">28.3</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">10 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics



Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">Direct NIF</td>
    <td style="white-space: nowrap; text-align: right">18.09 M</td>
    <td style="white-space: nowrap; text-align: right">0.00006 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;79.92%</td>
    <td style="white-space: nowrap; text-align: right">0.00004 ms</td>
    <td style="white-space: nowrap; text-align: right">0.00008 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap; text-align: right">0.00662 M</td>
    <td style="white-space: nowrap; text-align: right">0.151 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;99.70%</td>
    <td style="white-space: nowrap; text-align: right">0.128 ms</td>
    <td style="white-space: nowrap; text-align: right">0.33 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap; text-align: right">0.00053 M</td>
    <td style="white-space: nowrap; text-align: right">1.90 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;18.99%</td>
    <td style="white-space: nowrap; text-align: right">1.86 ms</td>
    <td style="white-space: nowrap; text-align: right">2.96 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Direct NIF</td>
    <td style="white-space: nowrap;text-align: right">18.09 M</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap; text-align: right">0.00662 M</td>
    <td style="white-space: nowrap; text-align: right">2733.54x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap; text-align: right">0.00053 M</td>
    <td style="white-space: nowrap; text-align: right">34321.88x</td>
  </tr>

</table>



Memory Usage

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Factor</th>
  </tr>
  <tr>
    <td style="white-space: nowrap">Direct NIF</td>
    <td style="white-space: nowrap">0 B</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap">600 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap">3926.85 B</td>
    <td>&mdash;</td>
  </tr>
</table>



Reduction Count

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Factor</th>
  </tr>
  <tr>
    <td style="white-space: nowrap">Direct NIF</td>
    <td style="white-space: nowrap">0</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap">83</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap">766.94</td>
    <td>&mdash;</td>
  </tr>
</table>