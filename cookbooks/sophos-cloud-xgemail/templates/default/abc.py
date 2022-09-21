relay_domains = hash:$config_directory/relay_domains
relay_domains = hash:$config_directory/relay_domains

cmd ='relay_domains=static:ALL'

def execute_postfix_cmd(cmd)
{
    argv = [
        'postmulti', '-i', postfix_instance_name, '-x',
        'postconf',cmd'
      ]
    pipe = subprocess.Popen(
             argv,
             stdout=subprocess.PIPE,
             stderr=subprocess.PIPE,
             close_fds=True)

    out, err = pipe.communicate()
    return pipe.returncode
}