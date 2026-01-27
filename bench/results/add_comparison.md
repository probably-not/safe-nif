Benchmark

Benchmark run from 2026-01-27 13:24:45.228184Z UTC

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
    <td style="white-space: nowrap">Direct NIF (unsafe)</td>
    <td style="white-space: nowrap; text-align: right">53.10 M</td>
    <td style="white-space: nowrap; text-align: right">0.00002 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;1573.62%</td>
    <td style="white-space: nowrap; text-align: right">0.00002 ms</td>
    <td style="white-space: nowrap; text-align: right">0.00003 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap; text-align: right">0.0133 M</td>
    <td style="white-space: nowrap; text-align: right">0.0752 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;81.06%</td>
    <td style="white-space: nowrap; text-align: right">0.0673 ms</td>
    <td style="white-space: nowrap; text-align: right">0.184 ms</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap; text-align: right">0.00060 M</td>
    <td style="white-space: nowrap; text-align: right">1.68 ms</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;8.18%</td>
    <td style="white-space: nowrap; text-align: right">1.64 ms</td>
    <td style="white-space: nowrap; text-align: right">2.15 ms</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">Direct NIF (unsafe)</td>
    <td style="white-space: nowrap;text-align: right">53.10 M</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap; text-align: right">0.0133 M</td>
    <td style="white-space: nowrap; text-align: right">3991.89x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap; text-align: right">0.00060 M</td>
    <td style="white-space: nowrap; text-align: right">89174.48x</td>
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
    <td style="white-space: nowrap">Direct NIF (unsafe)</td>
    <td style="white-space: nowrap">0 B</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap">552 B</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap">4072 B</td>
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
    <td style="white-space: nowrap">Direct NIF (unsafe)</td>
    <td style="white-space: nowrap">0</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">SafeNIF</td>
    <td style="white-space: nowrap">76.89</td>
    <td>&mdash;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">CLI Port</td>
    <td style="white-space: nowrap">329</td>
    <td>&mdash;</td>
  </tr>
</table>