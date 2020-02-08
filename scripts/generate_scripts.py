"""
Generate each script with customs variables by client
"""
import os
import glob
import json
import argparse
from pathlib import Path

# paths
path_cloud = str(Path(__file__).absolute().parent.parent)

# path: scripts powershell
path_ori_runbooks = '/scripts/runbooks/'
path_dest_runbooks = '/azure_automatiom_account/runbooks/'
path_automation_account = ''.join(path_cloud + path_dest_runbooks)

path_create_db_as                       = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-create_db-as-runbook.ps1')
path_apply_roles_as                     = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-apply-roles-as-runbook.ps1')
path_restore_bkp_as                     = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-restore-bkp-as-runbook.ps1')
path_send_email                         = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-send-email-runbook.ps1')
path_start_stop_as                      = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-start-stop-as-runbook.ps1')
path_update_bkp_as                      = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-update-bkp-as-runbook.ps1')
path_process_large_volume_tables_as     = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-process-large-volume-tables-as-runbook.ps1')
path_process_partitions_as              = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-daily-process-partitions-as-runbook.ps1')
path_process_partitions_monthly_as      = ''.join(path_cloud + path_ori_runbooks + 'PRODUCT_NAME-CLIENT_NAME-monthly-process-partitions-as-runbook.ps1')
path_update_modules                     = ''.join(path_cloud + path_ori_runbooks + 'update-modules-runbook.ps1')
path_update_certicate                   = ''.join(path_cloud + path_ori_runbooks + 'update-certificate-runbook.ps1')

# path: scripts tmsl
path_ori_tmsl = '/scripts/tmsl_mp/'
path_dest_tmsl = '/azure_analysis_services/tmsl/'
path_analysis_services = ''.join(path_cloud + path_dest_tmsl)

path_ori_role_admins = ''.join(path_cloud + path_ori_tmsl + 'role_admins.json')
path_ori_role_readers = ''.join(path_cloud + path_ori_tmsl + 'role_readers.json')

path_dest_role_admins = ''.join(path_cloud + path_dest_tmsl + 'role_admins.json')
path_dest_role_readers = ''.join(path_cloud + path_dest_tmsl + 'role_readers.json')

# path: partitions
path_partitions = ''.join(path_cloud + '/azure_analysis_services/partitions/')


def get_partitions_name(path_partitions: str, partition_to_exclude: str):
    """ Read all files in path_partitions and create a list
    :return: string in format of tuple because powershell need this ()
    special caraters.
    """
    partitions_files = []

    for file in glob.glob(path_partitions + '*.sql'):
        partition = os.path.splitext(os.path.basename(file))[0]
        partitions_files.append(partition)

    partitions_files.remove(partition_to_exclude) # Remove large volumne table
    partition_tuple = tuple(i for i in partitions_files)

    return str(partition_tuple)


def prepare_users_names_tmsl(list_users: str):
    list_users = list(list_users.split(','))
    list_name = []

    for user in list_users:
        d = {"memberName": user,
             "identityProvider": "AzureAD"}
        list_name.append(d)

    return str(json.dumps(list_name))


def prepare_tmsl(tmsl: str, local: str):
    """Prepare the path from local
    :return:
        Path of file tmsl
    """
    if local == 'origin':
        return ''.join(path_cloud + path_ori_tmsl + 'create_db_'+tmsl+'.json')
    else:
        return ''.join(path_cloud + path_dest_tmsl + 'create_db_'+tmsl+'.json')


def replace_tags(path: str = None,
                subscritpion_id: str = '0000',
                product_name: str = 'PRODUCT_NAME',
                client_name: str = 'mp',
                location: str = 'brazilsouth',
                tmsl_create_db_as: str = path_cloud,
                tmsl_role_admins_as: str = path_cloud,
                tmsl_role_readers_as: str = path_cloud,
                list_readers_users: str = '@company.com.br',
                list_admins_users: str = '@company.com.br',
                email_from: str = '@company.com.br',
                email_to: str = '@company.com.br',
                smtp_server: str = '',
                smtp_port: str = '587',
                large_volume_table: str = 'historic',
                column_to_split: str = 'idname',
                total_month: str = '12',
                list_partitions: str = '(part_1, part_2)') -> 'stream':
    return open(file=path, mode='r', encoding="utf-8")\
        .read()\
        .replace('<SUBSCRIPTION_ID>', subscritpion_id)\
        .replace('<PRODUCT_NAME>', product_name)\
        .replace('<CLIENT_NAME>', client_name)\
        .replace('<CLIENT_NAME_LOWER>', client_name.lower())\
        .replace('<LOCATION>', location)\
        .replace('<SCRIPT_CREATE_DB>', tmsl_create_db_as)\
        .replace('<SCRIPT_ROLE_ADMINS>', tmsl_role_admins_as)\
        .replace('<SCRIPT_ROLE_READERS>', tmsl_role_readers_as) \
        .replace('<LIST_READERS_USERS>', list_readers_users)\
        .replace('<LIST_ADMINS_USERS>', list_admins_users)\
        .replace('<EMAIL_FROM>', email_from)\
        .replace('<EMAIL_TO>', email_to)\
        .replace('<SMTP_SERVER>', smtp_server)\
        .replace('<SMTP_PORT>', smtp_port)\
        .replace('<LIST_PARTITIONS>', list_partitions)\
        .replace('<LARGE_VOLUME_TABLE>', large_volume_table)\
        .replace('<COLUMN_TO_SPLIT>', column_to_split)\
        .replace('<TOTAL_MONTH>', total_month)


def write_script(path_dest: str, file_name: str, script_content: str):
    """Create  script powershell to use in runbooks
    :return:
        file *.ps1
    """
    try:
        return open(''.join(path_dest + file_name), mode='w+', encoding="utf-8") \
            .write(script_content)
    except IOError:
        raise Exception('Request Error in ', file_name)


def main(subscritpion_id: str, data_source: str, product_name: str,
         client_name: str, location: str, list_admins: str, list_readers: str,
         large_volume_table: str, column_to_split: str, total_month: str,
         email_from: str, email_to: str, smtp_server: str, smtp_port: str):

    path_ori_create_db = prepare_tmsl(tmsl=data_source, local='origin')
    path_dest_create_db = prepare_tmsl(tmsl=data_source, local='destination')

    list_partitions = get_partitions_name(path_partitions=path_partitions,
                                          partition_to_exclude=large_volume_table)

    list_admins = prepare_users_names_tmsl(list_users=list_admins)
    list_readers = prepare_users_names_tmsl(list_users=list_readers)

    # tmsl
    stream_ori_create_db_as = replace_tags(path=path_ori_create_db,
                                           product_name=product_name,
                                           client_name=client_name,
                                           list_readers_users=list_readers,
                                           list_admins_users=list_admins)
    stream_ori_role_admins_as = replace_tags(path=path_ori_role_admins,
                                             product_name=product_name,
                                             client_name=client_name,
                                             list_admins_users=list_admins)
    stream_ori_role_readers = replace_tags(path=path_ori_role_readers,
                                           product_name=product_name,
                                           client_name=client_name,
                                           list_readers_users=list_readers)

    write_script(path_dest=path_analysis_services,
                 file_name=f'create_db_{data_source}.json',
                 script_content=stream_ori_create_db_as)
    write_script(path_dest=path_analysis_services,
                 file_name='role_admins.json',
                 script_content=stream_ori_role_admins_as)
    write_script(path_dest=path_analysis_services,
                 file_name='role_readers.json',
                 script_content=stream_ori_role_readers)

    # stream: tmsl
    stream_dest_create_db_as = open(file=path_dest_create_db,
                                    mode='r',
                                    encoding="utf-8").read()
    stream_dest_role_admins_as = open(file=path_dest_role_admins,
                                      mode='r',
                                      encoding="utf-8").read()
    stream_dest_role_readers_as = open(file=path_dest_role_readers,
                                       mode='r',
                                       encoding="utf-8").read()

    # runbooks
    stream_runbook_create_db_as = replace_tags(path=path_create_db_as,
                                               product_name=product_name,
                                               client_name=client_name,
                                               location=location,
                                               tmsl_create_db_as=stream_dest_create_db_as)
    stream_runbook_apply_roles_as = replace_tags(path=path_apply_roles_as,
                                                 product_name=product_name,
                                                 client_name=client_name,
                                                 location=location,
                                                 tmsl_role_admins_as=stream_dest_role_admins_as,
                                                 tmsl_role_readers_as=stream_dest_role_readers_as)
    stream_runbook_restore_bkp_as = replace_tags(path=path_restore_bkp_as,
                                                 product_name=product_name,
                                                 client_name=client_name,
                                                 location=location)
    stream_runbook_send_email = replace_tags(path=path_send_email,
                                             product_name=product_name,
                                             client_name=client_name,
                                             location=location,
                                             email_from=email_from,
                                             email_to=email_to,
                                             smtp_server=smtp_server,
                                             smtp_port=smtp_port)
    stream_runbook_start_stop_as = replace_tags(path=path_start_stop_as,
                                                product_name=product_name,
                                                client_name=client_name)
    stream_runbook_update_bkp_as = replace_tags(path=path_update_bkp_as,
                                                product_name=product_name,
                                                client_name=client_name,
                                                location=location)
    steam_runbook_process_large_volume_tables_as = replace_tags(
                                                    path=path_process_large_volume_tables_as,
                                                    product_name=product_name,
                                                    client_name=client_name,
                                                    location=location,
                                                    large_volume_table=large_volume_table,
                                                    column_to_split=column_to_split,
                                                    total_month=total_month)
    steam_runbook_process_partitions_as = replace_tags(
                                                    path=path_process_partitions_as,
                                                    product_name=product_name,
                                                    client_name=client_name,
                                                    location=location,
                                                    list_partitions=list_partitions)
    steam_runbook_process_partitions_monthly_as = replace_tags(
                                                    path=path_process_partitions_monthly_as,
                                                    product_name=product_name,
                                                    client_name=client_name,
                                                    location=location,
                                                    large_volume_table=large_volume_table,
                                                    column_to_split=column_to_split)
    steam_runbook_update_modules = replace_tags(path=path_update_modules,
                                                product_name=product_name,
                                                client_name=client_name)
    steam_runbook_update_certificate = replace_tags(path=path_update_certicate,
                                                    product_name=product_name,
                                                    client_name=client_name,
                                                    subscritpion_id=subscritpion_id)

    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-create-db-as-runbook.ps1',
                 script_content=stream_runbook_create_db_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-apply-roles-as-runbook.ps1',
                 script_content=stream_runbook_apply_roles_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-restore-bkp-as-runbook.ps1',
                 script_content=stream_runbook_restore_bkp_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-send-email-runbook.ps1',
                 script_content=stream_runbook_send_email)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-start-stop-as-runbook.ps1',
                 script_content=stream_runbook_start_stop_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-update-bkp-as-runbook.ps1',
                 script_content=stream_runbook_update_bkp_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-process-large-volume-tables-as-runbook.ps1',
                 script_content=steam_runbook_process_large_volume_tables_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-daily-process-partitions-as-runbook.ps1',
                 script_content=steam_runbook_process_partitions_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'{product_name}-{client_name}-monthly-process-partitions-as-runbook.ps1',
                 script_content=steam_runbook_process_partitions_monthly_as)
    write_script(path_dest=path_automation_account,
                 file_name=f'update-modules-runbook.ps1',
                 script_content=steam_runbook_update_modules)
    write_script(path_dest=path_automation_account,
                 file_name=f'update-certificate-runbook.ps1',
                 script_content=steam_runbook_update_certificate)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Generate each script with customs variables by client')
    parser.add_argument('--subscritpion_id',
                        type=str,
                        required=False,
                        help='Number subscritpion_id with 4 fileds')
    parser.add_argument('--data_source',
                        type=str,
                        default='oracle',
                        required=False,
                        help='oracle or postgresql')
    parser.add_argument('--product_name',
                        type=str,
                        default='PRODUCT_NAME',
                        required=False,
                        help='Name in lower case')
    parser.add_argument('--client_name',
                        type=str,
                        default='mp',
                        required=False,
                        help='Name in Upper case')
    parser.add_argument('--location',
                        type=str,
                        default='brazilsouth',
                        required=False,
                        help='Localization to create resources in Azure')
    parser.add_argument('--list_admins',
                        type=str,
                        default='[username@ad.com]',
                        required=False,
                        help='Users to role admins in analysis services')
    parser.add_argument('--list_readers',
                        type=str,
                        default='[username@ad.com]',
                        required=False,
                        help='Users to role readers in analysis services')
    parser.add_argument('--large_volume_table',
                        type=str,
                        default='fInfoProcessoMensal',
                        required=False,
                        help='Table`s name with need split partitions')
    parser.add_argument('--column_to_split',
                        type=str,
                        default='idanomesreferencia',
                        required=False,
                        help='Column`s name with need split partitions')
    parser.add_argument('--total_month',
                        type=str,
                        default='12',
                        required=False,
                        help='Range of month to storage in Analysis Services')
    parser.add_argument('--email_from',
                        type=str,
                        default='smtp@company.com.br',
                        required=False,
                        help='Sender email when runbook fail')
    parser.add_argument('--email_to',
                        type=str,
                        default='bruno.moura@company.com.br',
                        required=False,
                        help='Receiver email when runbooks fail.')
    parser.add_argument('--smtp_server',
                        type=str,
                        default='bruno.moura@company.com.br',
                        required=False,
                        help='Receiver email when runbooks fail.')
    parser.add_argument('--smtp_port',
                        type=str,
                        default='bruno.moura@company.com.br',
                        required=False,
                        help='Receiver email when runbooks fail.')

    args = parser.parse_args()  # <class 'argparse.ArgumentParser'>
    subscritpion_id = args.subscritpion_id
    data_source = args.data_source
    product_name = args.product_name
    client_name = args.client_name
    location = args.location
    list_admins = args.list_admins
    list_readers = args.list_readers
    large_volume_table = args.large_volume_table
    column_to_split = args.column_to_split
    total_month = args.total_month
    email_from = args.email_from
    email_to = args.email_to
    smtp_server = args.smtp_server
    smtp_port = args.smtp_port

    main(subscritpion_id,
         data_source,
         product_name,
         client_name,
         location,
         list_admins,
         list_readers,
         large_volume_table,
         column_to_split,
         total_month,
         email_from,
         email_to,
         smtp_server,
         smtp_port)
