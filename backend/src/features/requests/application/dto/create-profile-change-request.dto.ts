import { UpdateMyProfileDto } from '../../../employee/application/dto/update-my-profile.dto';

/** Same fields and validation as a direct self-service profile edit — the
 * difference is purely in how RequestsService handles it: submitted for
 * HR/Admin approval instead of applied immediately. */
export class CreateProfileChangeRequestDto extends UpdateMyProfileDto {}
