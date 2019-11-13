#!/usr/bin/env groovy

import jenkins.model.JenkinsLocationConfiguration

jlc = jenkins.model.JenkinsLocationConfiguration.get()
jlc.setUrl("https://{{ domain_name }}/")
jlc.save()
