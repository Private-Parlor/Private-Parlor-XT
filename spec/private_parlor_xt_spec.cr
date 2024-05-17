require "./spec_helper"

module PrivateParlorXT
  VERSION = "spec"

  # NOTE: Cannot test terminate_program as this exits the program
  # NOTE: Can't test start_tasks, as we do not store the created Tasks and the function returns nil.
  # NOTE: Can't test initialize_bot; it would be difficult to do so, and a failure in functionality here is evident immediately at runtime.

end
