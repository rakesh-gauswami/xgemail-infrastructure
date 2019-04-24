#!/usr/bin/env python
# vim: autoindent tabstop=4 softtabstop=4 shiftwidth=4 expandtab filetype=python

"""
Unit tests for the Xgemail diskutils utility.

Copyright 2019, Sophos Limited. All rights reserved.

'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
Sophos Limited and Sophos Group.  All other product and company
names mentioned are trademarks or registered trademarks of their
respective owners.
"""

import json
import unittest
import xgemail_firehose_transformation

class FirehoseTransformationHandlerTest(unittest.TestCase):
    def test_firehose_transformation(self):
        input_event = {
          "invocationId": "invocationIdExample",
          "deliveryStreamArn": "arn:aws:kinesis:EXAMPLE",
          "region": "eu-west-1",
          "records": [
			 {
			   "recordId": "49546986683135544286507457936321625675700192471156785154",
			   "approximateArrivalTimestamp": 1495072949453,
			   "data": "eyJAdGltZXN0YW1wIjoiMjAxOS0wNC0yMlQxNzo0NjowMi43ODUrMDA6MDAiLCJAdmVyc2lvbiI6MSwibWVzc2FnZSI6IlVuYXV0aG9yaXplZCBhY2Nlc3MgcmVxdWVzdCBieTogbWFpbCIsImxvZ2dlcl9uYW1lIjoiY29tLnNvcGhvcy5jbG91ZC5pbnRlcmNlcHRvcnMueGdlbWFpbC5YZ2VtYWlsQXV0aEludGVyY2VwdG9yIiwidGhyZWFkX25hbWUiOiJodHRwLW5pby04MDgwLWV4ZWMtMiIsImxldmVsIjoiV0FSTiIsImxldmVsX3ZhbHVlIjozMDAwMCwiaXAiOiI1Mi4zMS41OC4xMCIsInRrIjoiNTIuMzEuNTguMTAiLCJycSI6IjFiOTUxZmQxLTc0NWMtNDhhMS05ZGIwLTg2MTdiZDZkYjUwMiIsImxvZ19zaGlwcGVyIjoiZmlyZWhvc2UiLCJhY2NvdW50IjoiaW5mIiwiYXBwbGljYXRpb25fbmFtZSI6InhnZW1haWwiLCJob3N0bmFtZSI6ImlwLTE3Mi0xOS0xMDItMTM3LmV1LXdlc3QtMS5jb21wdXRlLmludGVybmFsIiwiaW5zdGFuY2VfaWQiOiJpLTBiYzZiMzVlYzc2MmUyYWNlIiwiaW5zdGFuY2VfdHlwZSI6InQzLmxhcmdlIiwiaW5zdGFuY2VfaXAiOiIxNzIuMTkuMTAyLjEzNyIsInJlZ2lvbiI6ImV1LXdlc3QtMSIsInNlcnZpY2VfdHlwZSI6InN2Y19tYWlsIiwidGFnIjoic29waG9zLnhnZW1haWwifQo="
			 },
			 {
			   "recordId":"49546986683135544286507457936321625675700192471156785154",
			   "approximateArrivalTimestamp":1495072949453,
			   "kinesisRecordMetadata":{
				 "sequenceNumber":"49545115243490985018280067714973144582180062593244200961",
				 "subsequenceNumber":"123456",
				 "partitionKey":"partitionKey-03",
				 "shardId":"shardId-000000000000",
				 "approximateArrivalTimestamp":1495072949453
			   },
			   "data":"ewogICAgIkB0aW1lc3RhbXAiOiAiMjAxOS0wNC0xNlQxODowMTo1NS43NzErMDA6MDAiLAogICAgIkB2ZXJzaW9uIjogMSwKICAgICJtZXNzYWdlIjogIlVua25vd24gZmVhdHVyZSBmbGFnIFwieGdlbWFpbC5uZXcuc3BhbS5jYXRlZ29yeS5tYXBwaW5nLmVuYWJsZWRcIjsgcmV0dXJuaW5nIGRlZmF1bHQgdmFsdWUiLAogICAgImxvZ2dlcl9uYW1lIjogImNvbS5sYXVuY2hkYXJrbHkuY2xpZW50LkxEQ2xpZW50IiwKICAgICJ0aHJlYWRfbmFtZSI6ICJtZXNzYWdpbmdUYXNrRXhlY3V0b3ItMTQ3IiwKICAgICJsZXZlbCI6ICJJTkZPIiwKICAgICJsZXZlbF92YWx1ZSI6IDIwMDAwLAogICAgInJxIjogImE3NzYwNDZhLTk2N2ItNDI5MS1iNjQ4LWFjZThjMTlmNWU2OSIsCiAgICAibG9nX3NoaXBwZXIiOiAiZmlyZWhvc2UiLAogICAgImFjY291bnQiOiAiZGV2IiwKICAgICJhcHBsaWNhdGlvbl9uYW1lIjogInhnZW1haWwtaW5ib3VuZCIsCiAgICAiaG9zdG5hbWUiOiAiaXAtMTcyLTE5LTEwMC0xOTYuZXUtd2VzdC0xLmNvbXB1dGUuaW50ZXJuYWwiLAogICAgImluc3RhbmNlX2lkIjogImktMGM4MGNlZGIxYzhiYTRhZjIiLAogICAgImluc3RhbmNlX3R5cGUiOiAidDMubGFyZ2UiLAogICAgImluc3RhbmNlX2lwIjogIjE3Mi4xOS4xMDAuMTk2IiwKICAgICJyZWdpb24iOiAiZXUtd2VzdC0xIiwKICAgICJzZXJ2aWNlX3R5cGUiOiAic3ZjX21haWxpbmJvdW5kIiwKICAgICJ0YWciOiAic29waG9zLnhnZW1haWwtaW5ib3VuZCIKfQ=="
			}
          ]
        }

        result = xgemail_firehose_transformation.firehose_transformation_handler(input_event, None)
        records = result['records']
        self.assertTrue(len(records) == 2)
        ok_record = records[0]
        drop_record = records[1]

        # first record is expected to be okay (not dropped)
        self.assertEquals('Ok', ok_record['result'])
        self.assertEquals('49546986683135544286507457936321625675700192471156785154', ok_record['recordId'])

        # second record is expected to be dropped
        self.assertEquals('Dropped', drop_record['result'])
        self.assertEquals('49546986683135544286507457936321625675700192471156785154', drop_record['recordId'])

if __name__ == "__main__":
    unittest.main()
