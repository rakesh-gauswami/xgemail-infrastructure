#!/usr/bin/env python
# vim: autoindent expandtab filetype=python shiftwidth=4 softtabstop=4 tabstop=4
#
# Generates a utilization report of how Sophos Email features
#
# Copyright 2019, Sophos Limited. All rights reserved.
#
# 'Sophos' and 'Sophos Anti-Virus' are registered trademarks of
# Sophos Limited and Sophos Group.  All other product and company
# names mentioned are trademarks or registered trademarks of their
# respective owners.
#

import argparse
import codecs
import json
import os
import sys

try:
    from fpdf import FPDF
except ImportError:
    pip.main(['install', 'fpdf'])
    from fpdf import FPDF

try:
    from pygal.style import DefaultStyle
except ImportError:
    pip.main(['install', 'pygal'])
    from pygal.style import DefaultStyle

import pygal

CHARTS_IGNORED_ATTRIBUTES = [
    'policyType',
    'xgemail/dkim/tag',
    'xgemail/dmarc/tag',
    'xgemail/has_feature',
    'xgemail/quarantine_summary/days',
    'xgemail/quarantine_summary/hours',
    'xgemail/quarantine_summary/timezone',
    'xgemail/spf/tag',
    'xgemail/spoofing/tag',
    'xgemail/smart_banner/untrusted/message',
    'xgemail/unscannable_content/tag',
    'xgemail/smart_banner/unknown/message',
    'xgemail/impersonation/tag_message',
    'xgemail/spam/bulk_tag',
    'xgemail/smart_banner/trusted/message',
    'xgemail/spam/suspected_tag',
]

def find_reports():
    return [f for f in os.listdir('.') if os.path.isfile(f) and f.endswith('.json')]

def create_charts(reports):
    for report in reports:
        with open(report, 'r') as r:
            json_report = json.loads(r.read())

            total_entries = json_report['xgemail/has_feature']['True']

            for policy_attribute in json_report:
                if policy_attribute in CHARTS_IGNORED_ATTRIBUTES:
                    continue

                filename = 'charts/{}.png'.format(policy_attribute.replace('/', '-'))
                chart = pygal.Bar(
                    legend_at_bottom=True,
                    print_values=True,
                    style=DefaultStyle(
                        value_font_size=20
                    ),
                    print_values_position='bottom'
                )
                chart.title = policy_attribute

                sum_of_hits = 0
                for value in json_report[policy_attribute]:
                    nr_of_hits = json_report[policy_attribute][value]
                    sum_of_hits += nr_of_hits
                    percentage = 100/float(total_entries) * float(nr_of_hits)
                    chart.add(u'{} ({:0.2f}%)'.format(value, percentage), nr_of_hits)

                if sum_of_hits < total_entries:
                    percentage = 100/float(total_entries) * float(total_entries - sum_of_hits)
                    chart.add(u'MISSING ({:0.2f}%)'.format(percentage), total_entries - sum_of_hits)

                chart.render_to_png(filename)
                print 'Created chart {}'.format(policy_attribute)

def create_pdf():
    image_pos = {
        0: (10, 0),
        1: (110, 0),
        2: (10, 70),
        3: (110, 70),
        4: (10, 140),
        5: (110, 140),
        6: (10, 210),
        7: (110, 210)
    }

    pdf = FPDF()
    charts_path = '{}/charts'.format(os.path.dirname(os.path.realpath(__file__)))



    images = [os.path.join(charts_path, f) for f in os.listdir(charts_path) if f.endswith('.png')]
    pdf.add_page()
    cur_image = 0
    for image in images:
        if cur_image > 0 and cur_image % 8 == 0:
            cur_image = 0
            pdf.add_page()

        pdf.image(
            image,
            image_pos[cur_image][0],
            image_pos[cur_image][1],
            88, # width,
            0, # height,
            'PNG'
        )
        cur_image += 1
    pdf.output('policy-analysis-eu-central-1.pdf', 'F')

def create_csv_from_json_reports(reports):
    for report in reports:
        csv_data = u''
        with open(report, 'r') as r:
            json_report = json.loads(r.read())

            total_entries = json_report['xgemail/has_feature']['True']

            for key in json_report:
                if len(json_report[key]) <= 0:
                    continue
                is_first_entry = True
                sum_of_hits = 0
                for value in json_report[key]:
                    nr_of_hits = json_report[key][value]
                    sum_of_hits += nr_of_hits
                    percentage = 100/float(total_entries) * float(nr_of_hits)
                    if is_first_entry:
                        csv_data += u'{},"{}",{},{:0.2f}%\n'.format(key, value, nr_of_hits, percentage)
                        is_first_entry = False
                    else:
                        csv_data += u',"{}",{},{:0.2f}%\n'.format(value, nr_of_hits, percentage)
                if sum_of_hits < total_entries:
                    percentage = 100/float(total_entries) * float(total_entries - sum_of_hits)
                    csv_data += u',UNAVAILABLE,{},{:0.2f}%\n'.format(total_entries - sum_of_hits, percentage)
                csv_data += u'\n'
        print csv_data
        with codecs.open(report.replace('.json', '.csv'), 'w', 'utf-8-sig') as f:
            f.write(u'{}'.format(csv_data))

if __name__ == "__main__":
    """
        Entrypoint into this script.
    """
    parser = argparse.ArgumentParser(description = 'Create report based on policy data retrieved from S3')
    parser.add_argument('--nocsv', action = 'store_true', help = 'Do not create a csv report file')
    parser.add_argument('--nographs', action = 'store_true', help = 'Do not create graphs')

    args = parser.parse_args()

    reports = find_reports()

    if not reports:
        print 'No JSON reports found in the current directory, exiting.'
        sys.exit(1)

    if not args.nocsv:
        create_csv_from_json_reports(reports)

    if not args.nographs:
        create_charts(reports)
        create_pdf()
